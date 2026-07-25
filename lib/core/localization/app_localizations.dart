import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Supported locales
const List<Locale> supportedLocales = [
  Locale('en', 'US'),
  Locale('tr', 'TR'),
];

const Locale defaultLocale = Locale('en', 'US');

// Locale state provider
final localeProvider = StateProvider<Locale>((ref) => defaultLocale);

// Helper to read locale
final localeStringProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.languageCode;
});

// App localization helper
class AppLocalizations {
  final String _locale;

  AppLocalizations(this._locale);

  // English translations
  static const Map<String, String> _en = {
    // App
    'appTitle': 'PriceWatch',

    // Bottom Nav
    'navHome': 'Home',
    'navPriceDrops': 'Price Drops',
    'navSettings': 'Settings',

    // Home Screen
    'homeTitle': 'PriceWatch',
    'nothingHereYet': 'Nothing here yet',
    'noProductsMessage': 'You haven\'t added any products yet.',
    'addFirstProduct': 'Add your first product',
    'searchProducts': 'Search products...',
    'somethingWentWrong': 'Something went wrong',
    'retry': 'Retry',

    // Add Product Screen
    'addProduct': 'Add Product',
    'productUrl': 'Product URL',
    'urlHint': 'https://...',
    'paste': 'Paste',
    'preview': 'Preview',
    'enterUrlForPreview': 'Enter a URL to see product preview',
    'targetPriceOptional': 'Target Price (Optional)',
    'targetPriceHint': 'Notify me when price drops to...',
    'notesOptional': 'Notes (Optional)',
    'notesHint': 'e.g., Birthday gift for Mom',
    'productAddedSuccess': 'Product added successfully',
    'failedToAddProduct': 'Failed to add product: ',
    'pleaseEnterUrl': 'Please enter a product URL',
    'similarProductWarning': 'You might already be tracking a similar product — group them instead?',
    'viewDetails': 'View details',

    // Price Drops Screen
    'priceDrops': 'Price Drops',
    'noPriceDrops': 'No price drops yet',
    'noPriceDropsMessage': 'When product prices drop, they\'ll appear here.',
    'filter': 'Filter',
    'filterByPriceDrop': 'Filter by Price Drop',
    'showPriceDropsOnly': 'Show Price Drops Only',
    'showAllProducts': 'Show All Products',
    'apply': 'Apply',
    'search': 'Search',
    'noPriceHistory': 'No price history available',
    'error': 'Error',

    // Product Detail Screen
    'allTimeLow': 'ALL-TIME LOW',
    'priceHistory': 'Price History',
    'days30': '30 DAYS',
    'days90': '90 DAYS',
    'allTime': 'ALL TIME',
    'priceChartPlaceholder': 'Price chart will be displayed here',
    'details': 'Details',
    'added': 'Added',
    'lastChecked': 'Last Checked',
    'priceChange': 'Price Change',
    'targetPrice': 'Target Price',
    'notes': 'Notes',
    'cheapest': 'Cheapest',
    'addLink': 'Add another site link to this group',
    'comparePrices': 'Compare Prices',
    'editProduct': 'Edit Product',
    'save': 'Save',
    'delete': 'Delete',
    'deleteProduct': 'Delete Product',
    'deleteConfirm': 'Are you sure you want to delete "',
    'cancel': 'Cancel',
    'never': 'Never',
    'minAgo': 'm ago',
    'hAgo': 'h ago',
    'dAgo': 'd ago',

    // Settings Screen
    'settings': 'Settings',
    'notifications': 'Notifications',
    'enableNotifications': 'Enable Notifications',
    'enableNotificationsSub': 'Get notified when prices drop',
    'checkFrequency': 'Check Frequency',
    'checkFrequencySub': 'How often to check prices',
    'data': 'Data',
    'backupData': 'Backup Data',
    'backupDataSub': 'Export your products and price history',
    'restoreData': 'Restore Data',
    'restoreDataSub': 'Import from backup file',
    'clearAllData': 'Clear All Data',
    'clearAllDataSub': 'Delete all products and history',
    'about': 'About',
    'version': 'Version',
    'language': 'Language',
    'languageSub': 'App display language',
    'english': 'English',
    'turkish': 'Turkish',
    'backupCreated': 'Backup created successfully',
    'backupFailed': 'Backup failed: ',
    'restoreRequiresFilePicker': 'To enable restore, add file_picker to pubspec.yaml',
    'clearAllDataTitle': 'Clear All Data',
    'clearAllDataMessage': 'This will delete all your products and price history. This action cannot be undone.',
    'dataCleared': 'All data cleared successfully',
    'failedToClearData': 'Failed to clear data: ',

    // Groups Screen
    'myGroups': 'My Groups',
    'createGroup': 'Create Group',
    'groupName': 'Group Name',
    'groupNameHint': 'e.g., Headphones',
    'groupCreated': 'Group created',
    'deleteGroup': 'Delete Group',
    'deleteGroupConfirm': 'Delete this group and remove all product links?',
    'noGroups': 'No groups yet',
    'noGroupsMessage': 'Organize your products into groups to compare prices.',
    'products': 'products',

    // Group Comparison Screen
    'trackingRetailers': 'Tracking ',
    'retailers': 'Retailers',
    'lowest': 'Lowest',

    // Time related
    'hour': '1 hour',
    'hours3': '3 hours',
    'hours6': '6 hours',
    'hours12': '12 hours',
    'hours24': '24 hours',
  };

  // Turkish translations
  static const Map<String, String> _tr = {
    // App
    'appTitle': 'FiyatTakip',

    // Bottom Nav
    'navHome': 'Ana Sayfa',
    'navPriceDrops': 'İndirimler',
    'navSettings': 'Ayarlar',

    // Home Screen
    'homeTitle': 'FiyatTakip',
    'nothingHereYet': 'Henüz bir şey yok',
    'noProductsMessage': 'Henüz hiç ürün eklemediniz.',
    'addFirstProduct': 'İlk ürününü ekle',
    'searchProducts': 'Ürün ara...',
    'somethingWentWrong': 'Bir hata oluştu',
    'retry': 'Tekrar Dene',

    // Add Product Screen
    'addProduct': 'Ürün Ekle',
    'productUrl': 'Ürün URL\'si',
    'urlHint': 'https://...',
    'paste': 'Yapıştır',
    'preview': 'Önizleme',
    'enterUrlForPreview': 'Önizleme görmek için bir URL girin',
    'targetPriceOptional': 'Hedef Fiyat (İsteğe Bağlı)',
    'targetPriceHint': 'Fiyat düşünce beni uyar...',
    'notesOptional': 'Notlar (İsteğe Bağlı)',
    'notesHint': 'Örn: Anneme doğum günü hediyesi',
    'productAddedSuccess': 'Ürün başarıyla eklendi',
    'failedToAddProduct': 'Ürün eklenemedi: ',
    'pleaseEnterUrl': 'Lütfen bir ürün URL\'si girin',
    'similarProductWarning': 'Benzer bir ürünü zaten takip ediyor olabilirsiniz — bunun yerine gruplamak ister misiniz?',
    'viewDetails': 'Detayları gör',

    // Price Drops Screen
    'priceDrops': 'İndirimler',
    'noPriceDrops': 'Henüz indirim yok',
    'noPriceDropsMessage': 'Ürün fiyatları düştüğünde burada görünecek.',
    'filter': 'Filtre',
    'filterByPriceDrop': 'İndirim Durumuna Göre Filtrele',
    'showPriceDropsOnly': 'Sadece İndirimleri Göster',
    'showAllProducts': 'Tüm Ürünleri Göster',
    'apply': 'Uygula',
    'search': 'Ara',
    'noPriceHistory': 'Fiyat geçmişi mevcut değil',
    'error': 'Hata',

    // Product Detail Screen
    'allTimeLow': 'EN DÜŞÜK FİYAT',
    'priceHistory': 'Fiyat Geçmişi',
    'days30': '30 GÜN',
    'days90': '90 GÜN',
    'allTime': 'TÜM ZAMANLAR',
    'priceChartPlaceholder': 'Fiyat grafiği burada görüntülenecek',
    'details': 'Detaylar',
    'added': 'Eklenme',
    'lastChecked': 'Son Kontrol',
    'priceChange': 'Fiyat Değişimi',
    'targetPrice': 'Hedef Fiyat',
    'notes': 'Notlar',
    'cheapest': 'En Ucuz',
    'addLink': 'Bu gruba başka bir site bağlantısı ekle',
    'comparePrices': 'Fiyatları Karşılaştır',
    'editProduct': 'Ürünü Düzenle',
    'save': 'Kaydet',
    'delete': 'Sil',
    'deleteProduct': 'Ürünü Sil',
    'deleteConfirm': '" ürününü silmek istediğinize emin misiniz?',
    'cancel': 'İptal',
    'never': 'Hiç',
    'minAgo': ' dk önce',
    'hAgo': ' s önce',
    'dAgo': ' g önce',

    // Settings Screen
    'settings': 'Ayarlar',
    'notifications': 'Bildirimler',
    'enableNotifications': 'Bildirimleri Aç',
    'enableNotificationsSub': 'Fiyat düşünce bildirim al',
    'checkFrequency': 'Kontrol Sıklığı',
    'checkFrequencySub': 'Fiyatlar ne sıklıkla kontrol edilsin',
    'data': 'Veri',
    'backupData': 'Veriyi Yedekle',
    'backupDataSub': 'Ürünleri ve fiyat geçmişini dışa aktar',
    'restoreData': 'Veriyi Geri Yükle',
    'restoreDataSub': 'Yedek dosyasından içe aktar',
    'clearAllData': 'Tüm Veriyi Temizle',
    'clearAllDataSub': 'Tüm ürünleri ve geçmişi sil',
    'about': 'Hakkında',
    'version': 'Sürüm',
    'language': 'Dil',
    'languageSub': 'Uygulama görüntüleme dili',
    'english': 'İngilizce',
    'turkish': 'Türkçe',
    'backupCreated': 'Yedek başarıyla oluşturuldu',
    'backupFailed': 'Yedekleme başarısız: ',
    'restoreRequiresFilePicker': 'Geri yüklemeyi etkinleştirmek için pubspec.yaml\'a file_picker ekleyin',
    'clearAllDataTitle': 'Tüm Veriyi Temizle',
    'clearAllDataMessage': 'Bu işlem tüm ürünlerinizi ve fiyat geçmişinizi silecektir. Bu işlem geri alınamaz.',
    'dataCleared': 'Tüm veriler başarıyla temizlendi',
    'failedToClearData': 'Veriler temizlenemedi: ',

    // Groups Screen
    'myGroups': 'Gruplarım',
    'createGroup': 'Grup Oluştur',
    'groupName': 'Grup Adı',
    'groupNameHint': 'Örn: Kulaklıklar',
    'groupCreated': 'Grup oluşturuldu',
    'deleteGroup': 'Grubu Sil',
    'deleteGroupConfirm': 'Bu grubu ve tüm ürün bağlantılarını silsin mi?',
    'noGroups': 'Henüz grup yok',
    'noGroupsMessage': 'Ürünlerinizi gruplara ayırarak fiyatları karşılaştırın.',
    'products': 'ürün',

    // Group Comparison Screen
    'trackingRetailers': 'Takip edilen ',
    'retailers': 'mağaza',
    'lowest': 'En Düşük',

    // Time related
    'hour': '1 saat',
    'hours3': '3 saat',
    'hours6': '6 saat',
    'hours12': '12 saat',
    'hours24': '24 saat',
  };

  String translate(String key) {
    switch (_locale) {
      case 'tr':
        return _tr[key] ?? _en[key] ?? key;
      default:
        return _en[key] ?? key;
    }
  }

  String translateWith(String key, {Map<String, String>? params}) {
    String text = translate(key);
    if (params != null) {
      params.forEach((key, value) {
        text = text.replaceAll('{$key}', value);
      });
    }
    return text;
  }
}

// Provider to get localized strings
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLocalizations(locale.languageCode);
});
