import 'package:equatable/equatable.dart';
import 'check_status.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final String productUrl;
  final String siteHost;
  final String siteDisplayName;
  final double initialPrice;
  final double currentPrice;
  final String currency;
  final double? targetPrice;
  final DateTime addedAt;
  final DateTime? lastCheckedAt;
  final CheckStatus lastCheckStatus;
  final bool isArchived;
  final String? notes;
  final List<String> tags;
  final int? notifyThresholdPercent;
  final String? groupId;

  const Product({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.productUrl,
    required this.siteHost,
    required this.siteDisplayName,
    required this.initialPrice,
    required this.currentPrice,
    required this.currency,
    this.targetPrice,
    required this.addedAt,
    this.lastCheckedAt,
    required this.lastCheckStatus,
    required this.isArchived,
    this.notes,
    required this.tags,
    this.notifyThresholdPercent,
    this.groupId,
  });

  Product copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? productUrl,
    String? siteHost,
    String? siteDisplayName,
    double? initialPrice,
    double? currentPrice,
    String? currency,
    double? targetPrice,
    DateTime? addedAt,
    DateTime? lastCheckedAt,
    CheckStatus? lastCheckStatus,
    bool? isArchived,
    String? notes,
    List<String>? tags,
    int? notifyThresholdPercent,
    String? groupId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      productUrl: productUrl ?? this.productUrl,
      siteHost: siteHost ?? this.siteHost,
      siteDisplayName: siteDisplayName ?? this.siteDisplayName,
      initialPrice: initialPrice ?? this.initialPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      currency: currency ?? this.currency,
      targetPrice: targetPrice ?? this.targetPrice,
      addedAt: addedAt ?? this.addedAt,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      lastCheckStatus: lastCheckStatus ?? this.lastCheckStatus,
      isArchived: isArchived ?? this.isArchived,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      notifyThresholdPercent: notifyThresholdPercent ?? this.notifyThresholdPercent,
      groupId: groupId ?? this.groupId,
    );
  }

  /// Returns a user-friendly site name.
  /// Uses the stored display name for known sites (Trendyol, Hepsiburada, N11),
  /// otherwise extracts the main domain name from the URL host
  /// (e.g. "www.trendyol.com" or "ty.trendyol.com" → "Trendyol").
  String get displaySiteName {
    const genericNames = [
      'Generic HTML Scraper',
      'Puppeteer (Headless Chrome)',
      'WebView Scraper',
    ];
    if (genericNames.contains(siteDisplayName)) {
      return extractDomainName(siteHost);
    }
    return siteDisplayName;
  }

  /// Extracts the main domain name from a host string.
  /// Handles subdomains like "ty.trendyol.com" → "Trendyol"
  /// and country TLDs like "mediamarkt.com.tr" → "Mediamarkt".
  static String extractDomainName(String host) {
    final clean = host.replaceFirst(RegExp(r'^www\.'), '');
    final parts = clean.split('.');

    if (parts.length < 2) return clean;

    // For common two-part TLDs like .com.tr, .co.uk, etc.
    // use the third-level domain if available
    final tldIndex = parts.length - 1;
    final sldIndex = parts.length - 2;

    // Check if second-level is a common TLD (com, co, org, net, gov, edu)
    const commonSecondLevel = {'com', 'co', 'org', 'net', 'gov', 'edu'};
    final secondLevel = parts[sldIndex].toLowerCase();

    String name;
    if (commonSecondLevel.contains(secondLevel) && parts.length > 2) {
      // e.g. "mediamarkt.com.tr" → use parts[tldIndex - 2]
      name = parts[tldIndex - 2];
    } else {
      // e.g. "trendyol.com" or "ty.trendyol.com" → use parts[sldIndex]
      name = parts[sldIndex];
    }

    if (name.isEmpty) return host;
    return name[0].toUpperCase() + name.substring(1);
  }

  double get priceChange => currentPrice - initialPrice;
  double get priceChangePercent => ((currentPrice - initialPrice) / initialPrice) * 100;
  bool get hasPriceDrop => currentPrice < initialPrice;

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        productUrl,
        siteHost,
        siteDisplayName,
        initialPrice,
        currentPrice,
        currency,
        targetPrice,
        addedAt,
        lastCheckedAt,
        lastCheckStatus,
        isArchived,
        notes,
        tags,
        notifyThresholdPercent,
        groupId,
      ];
}
