import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import '../scraper_interface.dart';

/// Universal WebView Scraper — the last-resort scraper that loads the page in
/// a real Android WebView with full JavaScript execution.
///
/// Handles:
///   • Anti-bot challenge pages (Imperva, Cloudflare, Akamai, PerimeterX)
///   • Client-side-only SPAs (React/Next.js/Vue/Svelte/Angular)
///   • Lazy-loaded and hydrated content
///   • Sites that block plain HTTP requests (403 / captcha)
///
/// Extraction strategy (per pass):
///   1. JSON-LD structured data
///   2. Global JS state objects (__NEXT_DATA__, __INITIAL_STATE__, etc.)
///   3. Meta tags (OG, product:*, Twitter)
///   4. Heuristic DOM selectors + text regex
///
/// Runs up to 4 extraction passes with increasing delays and scroll triggers
/// to handle late-hydrating SPAs.
class WebViewScraper implements ProductScraper {
  final Duration _timeout;

  WebViewScraper({
    Duration timeout = const Duration(seconds: 60),
  }) : _timeout = timeout;

  @override
  bool canHandle(Uri url) => true;

  @override
  String get displayName => 'WebView Scraper';

  @override
  List<String> get supportedHosts => [];

  @override
  Future<ScrapedProduct> scrape(Uri url) async {
    final completer = Completer<ScrapedProduct>();
    late WebViewController controller;

    try {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String finishedUrl) async {
              // Don't extract from intermediate challenge pages
              if (!completer.isCompleted) {
                await _runExtractionPipeline(controller, completer, url);
              }
            },
            onWebResourceError: (WebResourceError error) {
              // Only fail on main frame navigation errors, never on sub-resources
              if (error.isForMainFrame == true && !completer.isCompleted) {
                final desc = error.description.toLowerCase();
                // Ignore soft/benign main-frame "errors" (SSL warnings, etc.)
                if (!desc.contains('net::err_') &&
                    !desc.contains('neterror') &&
                    !desc.contains('name not resolved')) {
                  return;
                }
                completer.completeError(
                  ScraperException(
                    'WebView navigation error: ${error.description}',
                    errorType: _mapWebErrorToScraperError(error.errorType),
                  ),
                );
              }
            },
          ),
        )
        ..loadRequest(url);

      // Start timeout timer
      _startTimeoutTimer(completer);

      return await completer.future;
    } catch (e) {
      if (e is ScraperException) rethrow;
      throw ScraperException(
        'WebView error: $e',
        errorType: ScraperErrorType.unknown,
      );
    }
  }

  // ─────────────────────── Extraction Pipeline ───────────────────────

  Future<void> _runExtractionPipeline(
    WebViewController controller,
    Completer<ScrapedProduct> completer,
    Uri url,
  ) async {
    // Give the page a moment to finish initial rendering
    await Future.delayed(const Duration(milliseconds: 1500));

    // Up to 4 passes with increasing delays
    for (int pass = 0; pass < 4; pass++) {
      if (completer.isCompleted) return;

      if (pass > 0) {
        // Scroll to trigger lazy loading & hydration
        try {
          final scrollFraction = pass == 1 ? 3 : (pass == 2 ? 2 : 1);
          await controller.runJavaScript(
            'window.scrollTo(0, document.body.scrollHeight / $scrollFraction);',
          );
        } catch (_) {}
        // Increasing delays: 2s → 3s → 4s
        await Future.delayed(Duration(seconds: pass + 1));
      }

      if (completer.isCompleted) return;

      // Run the single combined extraction script
      try {
        final result = await controller.runJavaScriptReturningResult(
          _buildExtractionScript(),
        );

        final product = _parseJsResult(result);
        if (product != null && !completer.isCompleted) {
          completer.complete(product);
          return;
        }
      } catch (_) {
        // JS execution error — continue to next pass
      }
    }

    // All passes exhausted
    if (!completer.isCompleted) {
      completer.completeError(
        const ScraperException(
          'Could not extract product info from page after multiple attempts',
          errorType: ScraperErrorType.parseError,
        ),
      );
    }
  }

  // ─────────────────────── JS Extraction Script ───────────────────────
  //
  // Single IIFE that tries 4 strategies in order and returns the first
  // successful result as a JSON string, or null.

  String _buildExtractionScript() {
    // Using raw string to avoid Dart interpolation issues with $ in JS
    return r'''(function() {
  "use strict";
  try {
    // ── Helpers ──
    var IGNORED_PRICE_CLASSES = /old|strike|was|regular|original|list-price|market-price|taksit|installment|shipping|kargo|discount-rate|percent|crossed|line-through|deleted|before|eski|prev/i;
    var IGNORED_PRICE_TEXT = /taksit|kargo|\/ay|ücretsiz|bedava|free|aylık|monthly|ayda|x\s*ay|sipariş|indirim oranı|puan/i;
    var PRICE_REGEX = /(?:₺|TL|TRY|\$|USD|€|EUR|£)\s*[\d.,]+|[\d.,]+\s*(?:₺|TL|TRY|EUR|€|USD|\$|GBP|£)/i;

    function ok(s) { return s && typeof s === "string" && s.trim().length > 2; }

    function isIgnoredPriceEl(el) {
      var cls = (el.className || "").toString().toLowerCase();
      if (IGNORED_PRICE_CLASSES.test(cls)) return true;
      var p = el.parentElement;
      for (var i = 0; i < 2 && p; i++) {
        var pc = (p.className || "").toString().toLowerCase();
        if (/strike|old|crossed|line-through|deleted|eski/.test(pc)) return true;
        var st = (p.getAttribute("style") || "").toLowerCase();
        if (st.indexOf("line-through") >= 0) return true;
        p = p.parentElement;
      }
      var style = (el.getAttribute("style") || "").toLowerCase();
      return style.indexOf("line-through") >= 0;
    }

    function getNumericPrice(txt) {
      if (!txt || typeof txt !== "string") return null;
      if (IGNORED_PRICE_TEXT.test(txt)) return null;
      var cleaned = txt.replace(/[^\d.,]/g, "").trim();
      if (!cleaned) return null;
      var dots = (cleaned.match(/\./g) || []).length;
      var commas = (cleaned.match(/,/g) || []).length;
      var num = cleaned;
      if (dots > 0 && commas > 0) {
        if (cleaned.lastIndexOf(",") > cleaned.lastIndexOf(".")) {
          num = cleaned.replace(/\./g, "").replace(",", ".");
        } else {
          num = cleaned.replace(/,/g, "");
        }
      } else if (dots > 1) {
        num = cleaned.replace(/\./g, "");
      } else if (dots === 1 && commas === 0) {
        var parts = cleaned.split(".");
        if (parts[1].length === 3 && parts[0] !== "0") {
          num = cleaned.replace(".", "");
        }
      } else if (commas > 1) {
        num = cleaned.replace(/,/g, "");
      } else if (commas === 1 && dots === 0) {
        num = cleaned.replace(",", ".");
      }
      var val = parseFloat(num);
      return (val > 0 && isFinite(val)) ? val : null;
    }

    function detectCurrency(txt) {
      if (!txt) return "TRY";
      if (txt.indexOf("₺") >= 0 || txt.indexOf("TL") >= 0) return "TRY";
      if (txt.indexOf("€") >= 0 || txt.toLowerCase().indexOf("eur") >= 0) return "EUR";
      if (txt.indexOf("$") >= 0 || txt.toLowerCase().indexOf("usd") >= 0) return "USD";
      if (txt.indexOf("£") >= 0 || txt.toLowerCase().indexOf("gbp") >= 0) return "GBP";
      return "TRY";
    }

    function makeResult(name, priceText, image, currency) {
      if (!name || !priceText) return null;
      var p = (typeof priceText === "number") ? priceText : getNumericPrice(String(priceText));
      if (!p || p <= 0) return null;
      var cur = currency || detectCurrency(String(priceText));
      return JSON.stringify({ name: name.replace(/\s+/g, " ").trim(), price: String(p), image: image || null, currency: cur });
    }

    // ── Strategy 1: JSON-LD ──
    function tryJsonLd() {
      var scripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (var i = 0; i < scripts.length; i++) {
        var text = scripts[i].textContent;
        if (!text || !text.trim()) continue;
        try {
          var data = JSON.parse(text);
          var items = Array.isArray(data) ? data : (data["@graph"] || [data]);
          for (var j = 0; j < items.length; j++) {
            var item = items[j];
            if (!item) continue;
            // Recurse into mainEntity
            if (item.mainEntity) {
              var me = item.mainEntity;
              if (me.name && (me.offers || me.price)) item = me;
            }
            var type = (item["@type"] || "").toString().toLowerCase();
            var isProd = /product|offer|itempage|thing|vehicle|listing|realestate|buyaction|tradeaction/.test(type) || (item.name && (item.offers || item.price));
            if (!isProd) continue;

            var name = item.name || item.title;
            if (!ok(name)) continue;

            var price = null, currency = "TRY";
            var offers = item.offers || item.price;
            if (offers) {
              if (typeof offers === "number") { price = offers; }
              else if (typeof offers === "string") { price = offers; }
              else {
                var offer = Array.isArray(offers) ? offers[0] : offers;
                // Handle nested offers.offers
                if (offer && offer.offers && Array.isArray(offer.offers) && offer.offers.length > 0) {
                  offer = offer.offers[0];
                }
                if (offer) {
                  price = offer.price || offer.lowPrice || offer.highPrice || offer.amount;
                  if (offer.priceCurrency) currency = offer.priceCurrency;
                }
              }
            }

            var image = null;
            if (item.image) {
              if (typeof item.image === "string") image = item.image;
              else if (Array.isArray(item.image) && item.image.length > 0) {
                image = typeof item.image[0] === "string" ? item.image[0] : (item.image[0].url || item.image[0].contentUrl);
              }
              else if (item.image.url) image = item.image.url;
              else if (item.image.contentUrl) image = item.image.contentUrl;
            }

            var result = makeResult(name, price, image, currency);
            if (result) return result;
          }
        } catch(e) {}
      }
      return null;
    }

    // ── Strategy 2: Global JS state ──
    function tryGlobalState() {
      function getPrice(val, depth) {
        if (depth > 5) return null;
        if (val === undefined || val === null) return null;
        if (typeof val === "number" && val > 0) return String(val);
        if (typeof val === "string" && val.trim().length > 0) {
          if (IGNORED_PRICE_TEXT.test(val)) return null;
          var n = getNumericPrice(val);
          if (n && n > 0) return val.trim();
        }
        if (typeof val === "object" && val !== null) {
          var pKeys = ["amount","value","price","raw","displayValue","sellingPrice","discountedPrice","cost","currentPrice","text","formattedAmount"];
          for (var i = 0; i < pKeys.length; i++) {
            if (val[pKeys[i]] !== undefined) {
              var r = getPrice(val[pKeys[i]], (depth||0)+1);
              if (r) return r;
            }
          }
        }
        return null;
      }

      function searchObj(obj, depth) {
        if (!obj || depth > 10) return null;
        if (typeof obj !== "object") return null;
        if (Array.isArray(obj)) {
          for (var ai = 0; ai < Math.min(obj.length, 50); ai++) {
            if (typeof obj[ai] === "object") {
              var ar = searchObj(obj[ai], depth + 1);
              if (ar) return ar;
            }
          }
          return null;
        }

        var nameKeys = ["name","title","productName","itemTitle","itemName","heading","subject","productTitle","listingTitle","adTitle"];
        var foundName = null;
        for (var ni = 0; ni < nameKeys.length; ni++) {
          var v = obj[nameKeys[ni]];
          if (v && typeof v === "string" && v.trim().length > 2 && !v.startsWith("http") && v.indexOf("{") < 0) {
            foundName = v.trim();
            break;
          }
        }

        var foundPrice = null;
        var priceKeys = ["price","currentPrice","sellingPrice","discountedPrice","salePrice","listingPrice","amount","itemPrice","cost","formattedPrice","rawPrice","displayPrice","offers"];
        for (var pi = 0; pi < priceKeys.length; pi++) {
          if (obj[priceKeys[pi]] !== undefined && obj[priceKeys[pi]] !== null) {
            var p = getPrice(obj[priceKeys[pi]], 0);
            if (p) { foundPrice = p; break; }
          }
        }

        if (foundName && foundPrice) {
          var foundImage = null;
          var imgKeys = ["image","imageUrl","images","photo","photos","picture","pictures","itemImage","thumbnail","thumbnailUrl","mainImage","coverImage","media"];
          for (var ii = 0; ii < imgKeys.length; ii++) {
            var iv = obj[imgKeys[ii]];
            if (iv) {
              if (typeof iv === "string" && iv.trim()) { foundImage = iv; break; }
              if (Array.isArray(iv) && iv.length > 0) {
                foundImage = typeof iv[0] === "string" ? iv[0] : (iv[0] && (iv[0].url || iv[0].src || iv[0].original));
                if (foundImage) break;
              }
              if (typeof iv === "object" && iv !== null && (iv.url || iv.src)) {
                foundImage = iv.url || iv.src;
                break;
              }
            }
          }
          return makeResult(foundName, foundPrice, foundImage, null);
        }

        // Recurse into children
        var keys = Object.keys(obj);
        for (var ki = 0; ki < keys.length; ki++) {
          var child = obj[keys[ki]];
          if (child && typeof child === "object") {
            var cr = searchObj(child, depth + 1);
            if (cr) return cr;
          }
        }
        return null;
      }

      var candidates = [];
      try { if (window.__NEXT_DATA__) candidates.push(window.__NEXT_DATA__); } catch(e) {}
      try { if (window.__INITIAL_STATE__) candidates.push(window.__INITIAL_STATE__); } catch(e) {}
      try { if (window.__NUXT__) candidates.push(window.__NUXT__); } catch(e) {}
      try { if (window.__NUXT_DATA__) candidates.push(window.__NUXT_DATA__); } catch(e) {}
      try { if (window.__PRELOADED_STATE__) candidates.push(window.__PRELOADED_STATE__); } catch(e) {}
      try { if (window.__STATE__) candidates.push(window.__STATE__); } catch(e) {}
      try { if (window.pageData) candidates.push(window.pageData); } catch(e) {}
      try { if (window.__DATA__) candidates.push(window.__DATA__); } catch(e) {}
      try { if (window.APP_DATA) candidates.push(window.APP_DATA); } catch(e) {}
      try { if (window.__APOLLO_STATE__) candidates.push(window.__APOLLO_STATE__); } catch(e) {}
      try { if (window.product) candidates.push(window.product); } catch(e) {}
      try { if (window._product) candidates.push(window._product); } catch(e) {}
      try { if (window.item) candidates.push(window.item); } catch(e) {}
      try { if (window.__remixContext) candidates.push(window.__remixContext); } catch(e) {}
      try { if (window.__remixRoute__) candidates.push(window.__remixRoute__); } catch(e) {}
      try { if (window.__INITIAL_COMPONENT_STATE__) candidates.push(window.__INITIAL_COMPONENT_STATE__); } catch(e) {}

      for (var ci = 0; ci < candidates.length; ci++) {
        var r = searchObj(candidates[ci], 0);
        if (r) return r;
      }
      return null;
    }

    // ── Strategy 3: Meta tags ──
    function tryMetaTags() {
      function getMeta(selectors) {
        for (var si = 0; si < selectors.length; si++) {
          var el = document.querySelector(selectors[si]);
          if (el) {
            var c = el.getAttribute("content");
            if (c && c.trim().length > 0) return c.trim();
          }
        }
        return null;
      }

      var name = getMeta([
        'meta[property="og:title"]',
        'meta[name="twitter:title"]',
        'meta[name="title"]',
        'meta[property="product:name"]',
        'meta[name="product:title"]'
      ]);
      var priceStr = getMeta([
        'meta[property="product:price:amount"]',
        'meta[property="product:sale_price:amount"]',
        'meta[property="og:price:amount"]',
        'meta[name="twitter:data1"]',
        'meta[name="twitter:label1"]'
      ]);
      var currency = getMeta([
        'meta[property="product:price:currency"]',
        'meta[property="og:price:currency"]'
      ]);

      if (name && priceStr) {
        var image = getMeta([
          'meta[property="og:image"]',
          'meta[property="og:image:url"]',
          'meta[property="og:image:secure_url"]',
          'meta[name="twitter:image"]',
          'meta[name="twitter:image:src"]'
        ]);
        return makeResult(name, priceStr, image, currency);
      }
      return null;
    }

    // ── Strategy 4: Heuristic DOM ──
    function tryDom() {
      // Find title
      var title = null;
      var titleSel = [
        '[data-aut-id="itemTitle"]',
        '[data-aut-id*="title"]',
        '[data-aut-id*="name"]',
        '[data-qa*="title"]',
        '[data-qa*="name"]',
        '[data-qa="product-name"]',
        '[data-testid*="title"]',
        '[data-testid*="name"]',
        '[data-testid="product-name"]',
        '[data-test*="title"]',
        '[data-test-id*="title"]',
        '[data-test-id="product-name"]',
        'h1.product-name',
        'h1.pr-new-br',
        'h1.proName',
        'h1.pdp-title',
        'h1.pro-name',
        'h1[itemprop="name"]',
        'h1',
        '[itemprop="name"]',
        '.product-title-text',
        '.product-name-text',
        '.product-detail-name',
        '.product-detail-title',
        '.name-text',
        '.title-text',
        '.product-display-name',
        '.product-header-title',
        '.prd-title',
        '.product-header-title',
        'h2.product-title',
        'h2.product-name',
        '[class*="product-title"]',
        '[class*="product-name"]',
        '[class*="productTitle"]',
        '[class*="productName"]',
        '[class*="item-title"]',
        '[class*="item-name"]',
        '[class*="itemTitle"]',
        '[class*="itemName"]',
        '[class*="ad-title"]',
        '[class*="listing-title"]',
        '[class*="pdp-title"]',
        '[class*="title"]',
        '[class*="heading"]'
      ];
      for (var ti = 0; ti < titleSel.length && !title; ti++) {
        try {
          var els = document.querySelectorAll(titleSel[ti]);
          for (var ei = 0; ei < els.length && !title; ei++) {
            var txt = (els[ei].innerText || els[ei].textContent || "").trim();
            if (txt.length > 2 && txt.length < 500) {
              title = txt.replace(/\s+/g, " ").trim();
            }
          }
        } catch(e) {}
      }
      if (!title) {
        var t = document.title;
        if (t) {
          var seps = [" - ", " | ", " — ", " :: ", " » "];
          for (var si = 0; si < seps.length; si++) {
            if (t.indexOf(seps[si]) > 0) { t = t.split(seps[si])[0]; break; }
          }
          title = t.trim();
        }
      }

      // Find price
      var priceText = null;
      var priceSel = [
        '[data-aut-id="itemPrice"]',
        '[data-aut-id*="price"]',
        '[data-aut-id*="fiyat"]',
        '[data-qa*="price"]',
        '[data-qa*="fiyat"]',
        '[data-qa="price"]',
        '[data-qa="fiyat"]',
        '[data-testid*="price"]',
        '[data-testid*="fiyat"]',
        '[data-testid="price-current"]',
        '[data-test*="price"]',
        '[data-test-id*="price"]',
        '[itemprop="price"]',
        'meta[property="product:price:amount"]',
        'meta[property="og:price:amount"]',
        '.newPrice ins',
        '.newPrice',
        '.prc-dsc',
        '.prc-slg',
        '.prc-org',
        '.prc-hp',
        '.pdp-price',
        '.product-price-container .current',
        '[class*="current-price"]',
        '[class*="sale-price"]',
        '[class*="selling-price"]',
        '[class*="final-price"]',
        '[class*="special-price"]',
        '[class*="discounted-price"]',
        '[class*="product-price"]',
        '[class*="price-new"]',
        '[class*="price-box"]',
        '[class*="price-container"]',
        '[class*="price-tag"]',
        '[class*="price-tag-text"]',
        '[class*="price-display"]',
        '[class*="price-value"]',
        '[class*="price-text"]',
        '[class*="price-amount"]',
        '[class*="fiyat"]',
        '[class*="fiyat-kutu"]',
        '[class*="fiyat-bilgisi"]',
        '[class*="price"]',
        '.price',
        '.fiyat',
        '.offer-price',
        '.display-price',
        '.amount'
      ];
      for (var pi = 0; pi < priceSel.length && !priceText; pi++) {
        try {
          var pels = document.querySelectorAll(priceSel[pi]);
          for (var pei = 0; pei < pels.length && !priceText; pei++) {
            if (isIgnoredPriceEl(pels[pei])) continue;
            var ptxt = (pels[pei].getAttribute("content") || pels[pei].innerText || pels[pei].textContent || "").trim();
            if (!ptxt || IGNORED_PRICE_TEXT.test(ptxt)) continue;
            var pn = getNumericPrice(ptxt);
            if (pn && pn > 0) priceText = ptxt;
          }
        } catch(e) {}
      }

      // Fallback: leaf text nodes with currency
      if (!priceText) {
        var tags = ["span","div","p","b","strong","em","h1","h2","h3","h4","td"];
        for (var tgi = 0; tgi < tags.length && !priceText; tgi++) {
          try {
            var tels = document.querySelectorAll(tags[tgi]);
            for (var tei = 0; tei < tels.length && !priceText; tei++) {
              if (tels[tei].children.length > 0) continue;
              if (isIgnoredPriceEl(tels[tei])) continue;
              var tt = (tels[tei].innerText || "").trim();
              if (tt.length > 100 || !tt) continue;
              if (IGNORED_PRICE_TEXT.test(tt)) continue;
              if (PRICE_REGEX.test(tt)) {
                var tn = getNumericPrice(tt);
                if (tn && tn > 0) priceText = tt;
              }
            }
          } catch(e) {}
        }
      }

      // Find image
      var image = null;
      var imgSel = [
        '[data-aut-id="itemImage"] img',
        '[data-aut-id="itemImage"]',
        '[data-aut-id*="image"] img',
        '[data-aut-id*="image"]',
        '[data-aut-id*="photo"] img',
        '[data-qa*="image"] img',
        '[data-qa*="image"]',
        '[data-testid*="image"] img',
        '[data-testid*="image"]',
        '[data-test*="image"] img',
        'meta[property="og:image"]',
        'meta[property="og:image:url"]',
        'meta[property="og:image:secure_url"]',
        'meta[name="twitter:image"]',
        'meta[name="twitter:image:src"]',
        '[itemprop="image"]',
        'img[itemprop="image"]',
        '[class*="gallery"] img',
        '[class*="photo"] img',
        '[class*="picture"] img',
        '[class*="slider"] img',
        '[class*="carousel"] img',
        '[class*="product-image"] img',
        '[class*="product-photo"] img',
        '[class*="pdp"] img',
        '[class*="detail"] img',
        '[class*="hero"] img',
        '[class*="main-image"] img',
        '[class*="zoom"] img',
        'img[src*="product"]',
        'img[src*="item"]',
        'img'
      ];
      var imgAttrs = ["content","data-zoom-image","data-high-res","data-original","data-full","data-large","data-src","data-lazy-src","data-lazy","srcset","src"];
      for (var imi = 0; imi < imgSel.length && !image; imi++) {
        try {
          var iels = document.querySelectorAll(imgSel[imi]);
          for (var iei = 0; iei < iels.length && !image; iei++) {
            for (var iai = 0; iai < imgAttrs.length && !image; iai++) {
              var val = iels[iei].getAttribute(imgAttrs[iai]);
              if (!val || !val.trim()) continue;
              var u = val.trim();
              if (u.indexOf("data:image/") === 0 || u.indexOf("blob:") === 0) continue;
              if (/blank\.gif|pixel\.gif|spacer\.gif|transparent\.png|1x1\.|logo|avatar|icon/i.test(u)) continue;
              // Handle srcset
              if (u.indexOf(",") >= 0) {
                var parts = u.split(",");
                u = parts[parts.length - 1].trim().split(/\s+/)[0];
              }
              if (u.indexOf("//") === 0) u = "https:" + u;
              if (u.indexOf("http") === 0) image = u;
            }
          }
        } catch(e) {}
      }

      if (ok(title) && priceText) {
        return makeResult(title, priceText, image, null);
      }
      return null;
    }

    // ── Run strategies in order ──
    var r;
    r = tryJsonLd();    if (r) return r;
    r = tryGlobalState(); if (r) return r;
    r = tryMetaTags();  if (r) return r;
    r = tryDom();       if (r) return r;
    return null;

  } catch(e) {
    return null;
  }
})()''';
  }

  // ─────────────────────── Result Parsing ───────────────────────

  ScrapedProduct? _parseJsResult(Object result) {
    final raw = result.toString().trim();
    if (raw.isEmpty || raw == 'null' || raw == 'undefined') return null;

    try {
      String jsonStr = raw;
      // WebView sometimes wraps the result in extra quotes
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonStr.substring(1, jsonStr.length - 1);
        // Unescape
        jsonStr = jsonStr
            .replaceAll('\\"', '"')
            .replaceAll('\\\\', '\\')
            .replaceAll('\\/', '/');
      }

      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return null;

      final name = decoded['name']?.toString();
      final priceStr = decoded['price']?.toString();
      final image = decoded['image']?.toString();
      final currency = decoded['currency']?.toString() ?? 'TRY';

      if (name == null || name.trim().length < 3) return null;
      if (priceStr == null) return null;

      final price = double.tryParse(priceStr);
      if (price == null || price <= 0) return null;

      String? imageUrl = image;
      if (imageUrl != null) {
        if (imageUrl.isEmpty || imageUrl == 'null' || imageUrl == 'undefined') {
          imageUrl = null;
        }
      }

      return ScrapedProduct(
        name: name.replaceAll(RegExp(r'\s+'), ' ').trim(),
        imageUrl: imageUrl,
        price: price,
        currency: currency,
      );
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────── Timeout & Error Mapping ───────────────────────

  void _startTimeoutTimer(Completer<ScrapedProduct> completer) {
    Future.delayed(_timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          const ScraperException(
            'WebView scraping timeout',
            errorType: ScraperErrorType.networkError,
          ),
        );
      }
    });
  }

  ScraperErrorType _mapWebErrorToScraperError(WebResourceErrorType? errorType) {
    if (errorType == null) return ScraperErrorType.unknown;
    switch (errorType) {
      case WebResourceErrorType.hostLookup:
      case WebResourceErrorType.connect:
      case WebResourceErrorType.timeout:
        return ScraperErrorType.networkError;
      default:
        return ScraperErrorType.unknown;
    }
  }
}
