import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static final Map<String, Map<String, String>> _translations = {
    'ar': {
      'Commission Data': 'بيانات العمولة',
      'Dashboard / Commission Data': 'لوحة التحكم / بيانات العمولة',
      'Search by name, phone, or post code...': 'البحث بالاسم أو الهاتف أو الرمز البريدي...',
      'Filter by Bank': 'تصفية حسب البنك',
      'All Banks': 'جميع البنوك',
      'APPLY FILTERS': 'تطبيق الفلاتر',
      'No commission data available': 'لا توجد بيانات عمولة',
      'Commission requests will appear here': 'طلبات العمولة ستظهر هنا',
      "You're all caught up!": 'أنت على اطلاع!',
      'No commission data found': 'لم يتم العثور على بيانات العمولة',
      'Name': 'الاسم',
      'Phone': 'الهاتف',
      'Bank': 'البنك',
      'Commission Amount': 'مبلغ العمولة',
      'Post Code': 'الرمز البريدي',
      'Request Date': 'تاريخ الطلب',
      'Actions': 'الإجراءات',
      'Notes': 'ملاحظات',
      'Commission Details': 'تفاصيل العمولة',
      'View Receipt': 'عرض الإيصال',
      'View Details': 'عرض التفاصيل',
      'Delete Commission': 'حذف العمولة',
      'No receipt image available': 'لا توجد صورة للإيصال',
      'No': 'رقم',
    },
    'de': {
      'Commission Data': 'Provisionsdaten',
      'Dashboard / Commission Data': 'Dashboard / Provisionsdaten',
      'Search by name, phone, or post code...': 'Suche nach Name, Telefon oder Postleitzahl...',
      'Filter by Bank': 'Nach Bank filtern',
      'All Banks': 'Alle Banken',
      'APPLY FILTERS': 'FILTER ANWENDEN',
      'No commission data available': 'Keine Provisionsdaten verfügbar',
      'Commission requests will appear here': 'Provisionsanfragen erscheinen hier',
      "You're all caught up!": 'Du bist auf dem neuesten Stand!',
      'No commission data found': 'Keine Provisionsdaten gefunden',
      'Name': 'Name',
      'Phone': 'Telefon',
      'Bank': 'Bank',
      'Commission Amount': 'Provisionsbetrag',
      'Post Code': 'Postleitzahl',
      'Request Date': 'Anfragedatum',
      'Actions': 'Aktionen',
      'Notes': 'Notizen',
      'Commission Details': 'Provisionsdetails',
      'View Receipt': 'Beleg anzeigen',
      'View Details': 'Details anzeigen',
      'Delete Commission': 'Provision löschen',
      'No receipt image available': 'Kein Belegbild verfügbar',
      'No': 'Nr',
    },
    'tr': {
      'Commission Data': 'Komisyon Verileri',
      'Dashboard / Commission Data': 'Pano / Komisyon Verileri',
      'Search by name, phone, or post code...': 'İsim, telefon veya posta kodu ile ara...',
      'Filter by Bank': 'Bankaya göre filtrele',
      'All Banks': 'Tüm Bankalar',
      'APPLY FILTERS': 'FİLTRELERİ UYGULA',
      'No commission data available': 'Komisyon verisi yok',
      'Commission requests will appear here': 'Komisyon talepleri burada görünecek',
      "You're all caught up!": 'Her şey güncel!',
      'No commission data found': 'Komisyon verisi bulunamadı',
      'Name': 'İsim',
      'Phone': 'Telefon',
      'Bank': 'Banka',
      'Commission Amount': 'Komisyon Tutarı',
      'Post Code': 'Posta Kodu',
      'Request Date': 'Talep Tarihi',
      'Actions': 'İşlemler',
      'Notes': 'Notlar',
      'Commission Details': 'Komisyon Detayları',
      'View Receipt': 'Makbuzu Görüntüle',
      'View Details': 'Detayları Görüntüle',
      'Delete Commission': 'Komisyonu Sil',
      'No receipt image available': 'Makbuz resmi yok',
      'No': 'No',
    },
  };

  static final Map<String, Map<String, String>> _bankTranslations = {
    'ar': {
      'MTM Account': 'حساب MTM',
      'mtm account': 'حساب MTM',
      '#MTM Account': 'حساب MTM',
      'MTM': 'MTM',
      'syriatel': 'سيريتل',
      'Syriatel': 'سيريتل',
    },
    'de': {
      'MTM Account': 'MTM Konto',
      'mtm account': 'MTM Konto',
      '#MTM Account': 'MTM Konto',
      'MTM': 'MTM',
      'syriatel': 'syriatel',
      'Syriatel': 'syriatel',
    },
    'tr': {
      'MTM Account': 'MTM Hesabı',
      'mtm account': 'MTM Hesabı',
      '#MTM Account': 'MTM Hesabı',
      'MTM': 'MTM',
      'syriatel': 'syriatel',
      'Syriatel': 'syriatel',
    },
  };

  static String get currentLanguageCode {
    try {
      if (_prefs != null) {
        return _prefs!.getString('admin_language') ?? 'en';
      }
    } catch (_) {}
    return 'en';
  }

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {}
  }

  static Future<void> setLanguage(String languageCode) async {
    if (_prefs != null) {
      await _prefs!.setString('admin_language', languageCode);
    }
  }

  static String translate(String key, [String? languageCode]) {
    final lang = languageCode ?? currentLanguageCode;
    return _translations[lang]?[key] ?? _translations['en']?[key] ?? key;
  }

  static String translateBank(String bankName, [String? languageCode]) {
    final lang = languageCode ?? currentLanguageCode;
    if (lang == 'en') return bankName;
    
    String result = bankName;
    final translations = _bankTranslations[lang] ?? {};
    
    // Handle partial matches - find and replace bank names within the string
    // Order matters: longer patterns first
    final patterns = [
      '#MTM Account',
      'MTM Account',
      'mtm account',
      'syriatel',
      'Syriatel',
    ];
    
    for (final pattern in patterns) {
      if (result.toLowerCase().contains(pattern.toLowerCase())) {
        final translation = translations[pattern];
        if (translation != null) {
          result = result.replaceAll(RegExp(RegExp.escape(pattern), caseSensitive: false), translation);
        }
      }
    }
    
    // Wrap numbers in LTR override to prevent RTL mixing issues
    // This ensures phone numbers like 9654555+ display correctly in Arabic
    result = _wrapNumbersWithLTR(result);
    
    return result;
  }
  
  static String _wrapNumbersWithLTR(String text) {
    // Fix: ensure + is at the beginning (handle cases like "55555+")
    return text.replaceAllMapped(RegExp(r'(\d+)\+'), (Match m) => '+${m.group(1)}');
  }

  static String fixPhoneNumber(String phone) {
    if (phone.isEmpty) return phone;
    String result = phone.trim();
    // If + is at end, move to front
    if (result.endsWith('+')) {
      result = '+$result'.substring(0, result.length);
      result = '+' + result.substring(0, result.length - 1);
    }
    return result;
  }

  static bool isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]');
    return arabicRegex.hasMatch(text);
  }

  static TextDirection getTextDirection([String? languageCode]) {
    final lang = languageCode ?? currentLanguageCode;
    return lang == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }

  static TextAlign getTextAlign([String? languageCode]) {
    final lang = languageCode ?? currentLanguageCode;
    return lang == 'ar' ? TextAlign.right : TextAlign.left;
  }

  static bool get isRtl => currentLanguageCode == 'ar';
}
