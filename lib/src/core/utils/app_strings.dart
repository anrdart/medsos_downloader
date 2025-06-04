import '../services/language_service.dart';

class AppStrings {
  static SupportedLanguage get _currentLanguage =>
      LanguageService.instance.currentLanguage;

  // App Information
  static String get appName => "ANR Saver";
  static String get appSlogan {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Pemutar Video Ultimate Anda";
      case SupportedLanguage.english:
        return "Your Ultimate Video Saver";
    }
  }

  // UI Elements
  static String get videoLink {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Tautan video";
      case SupportedLanguage.english:
        return "Video link";
    }
  }

  static String get inputLinkFieldText {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Tempel tautan video di sini";
      case SupportedLanguage.english:
        return "Paste video link here";
    }
  }

  static String get download {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Unduh";
      case SupportedLanguage.english:
        return "Download";
    }
  }

  static String get paste {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Tempel";
      case SupportedLanguage.english:
        return "Paste";
    }
  }

  static String get downloading {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Mengunduh...";
      case SupportedLanguage.english:
        return "Downloading...";
    }
  }

  static String get downloads {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Unduhan";
      case SupportedLanguage.english:
        return "Downloads";
    }
  }

  static String get videoLinkRequired {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Tautan video diperlukan";
      case SupportedLanguage.english:
        return "Video link is Required";
    }
  }

  static String get downloadSuccess {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Unduhan berhasil";
      case SupportedLanguage.english:
        return "Download success";
    }
  }

  static String get play {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Putar";
      case SupportedLanguage.english:
        return "Play";
    }
  }

  static String get retryDownload {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Coba unduh lagi";
      case SupportedLanguage.english:
        return "Retry download";
    }
  }

  static String get downloadFall {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Unduhan gagal";
      case SupportedLanguage.english:
        return "Download failed";
    }
  }

  static String get permissionsRequired {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Izin diperlukan, Silakan terima izin dan coba lagi";
      case SupportedLanguage.english:
        return "Permissions is required, Please accept permissions and try again";
    }
  }

  static String get oldDownloads {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Unduhan Lama";
      case SupportedLanguage.english:
        return "Old Downloads";
    }
  }

  static String get darkMode {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Mode Gelap";
      case SupportedLanguage.english:
        return "Dark Mode";
    }
  }

  static String get lightMode {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Mode Terang";
      case SupportedLanguage.english:
        return "Light Mode";
    }
  }

  // Language Settings
  static String get language {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Bahasa";
      case SupportedLanguage.english:
        return "Language";
    }
  }

  static String get languageSettings {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Pengaturan Bahasa";
      case SupportedLanguage.english:
        return "Language Settings";
    }
  }

  static String get chooseLanguage {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Pilih Bahasa";
      case SupportedLanguage.english:
        return "Choose Language";
    }
  }

  static String get supportedPlatforms {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Platform yang Didukung:";
      case SupportedLanguage.english:
        return "Supported Platforms:";
    }
  }

  // RedNote specific messages
  static String get redNoteDetected {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Konten RedNote terdeteksi!";
      case SupportedLanguage.english:
        return "RedNote content detected!";
    }
  }

  static String get redNoteComingSoon {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "RedNote sekarang didukung! Mencoba mengekstrak konten...";
      case SupportedLanguage.english:
        return "RedNote is now supported! Trying to extract content...";
    }
  }

  static String get redNoteDevelopment {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Ekstraksi konten RedNote gagal. Silakan coba lagi nanti.";
      case SupportedLanguage.english:
        return "RedNote content extraction failed. Please try again later.";
    }
  }

  static String get redNoteConfigGuide {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Dukungan RedNote:\n✅ API dasar bekerja\n⚡ Fitur lanjutan tersedia dengan Apify";
      case SupportedLanguage.english:
        return "RedNote support:\n✅ Basic API working\n⚡ Enhanced features available with Apify";
    }
  }

  // Donation Dialog
  static String get supportDeveloper {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Dukung Developer";
      case SupportedLanguage.english:
        return "Support Developer";
    }
  }

  static String get helpKeepAppFree {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Bantu menjaga aplikasi ini gratis & terbaru";
      case SupportedLanguage.english:
        return "Help keep this app free & updated";
    }
  }

  static String get scanQrisCode {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Pindai Kode QRIS";
      case SupportedLanguage.english:
        return "Scan QRIS Code";
    }
  }

  static String get useIndonesianEWallet {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Gunakan aplikasi e-wallet atau mobile banking Indonesia";
      case SupportedLanguage.english:
        return "Use any Indonesian e-wallet or mobile banking app";
    }
  }

  static String get qrisImageNotFound {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "Gambar QRIS tidak ditemukan";
      case SupportedLanguage.english:
        return "QRIS image not found";
    }
  }

  static String get thankYouSupport {
    switch (_currentLanguage) {
      case SupportedLanguage.indonesian:
        return "❤️ Terima kasih atas dukungannya! ❤️";
      case SupportedLanguage.english:
        return "❤️ Thank you for your support! ❤️";
    }
  }

  // Helper method to get localized platform name
  static String getPlatformName(String platform) {
    if (_currentLanguage == SupportedLanguage.indonesian) {
      switch (platform.toLowerCase()) {
        case 'facebook':
          return 'Facebook';
        case 'instagram':
          return 'Instagram';
        case 'tiktok':
          return 'TikTok';
        case 'youtube':
          return 'YouTube';
        case 'rednote':
          return 'RedNote';
        case 'snapchat':
          return 'Snapchat';
        default:
          return platform;
      }
    }
    return platform; // English names are already correct
  }
}
