/// API Configuration for external services
/// Users can add their API tokens here for enhanced functionality
class ApiConfig {
  /// Apify API token for RedNote downloads
  /// Get your token from: https://console.apify.com/account/integrations
  /// Sign up for free account and get API token
  static const String? apifyApiToken = null; // Add your token here

  /// RapidAPI keys (multiple keys for better rate limits)
  /// Note: Update these keys if you get 403 "not subscribed" errors
  static const List<String> rapidApiKeys = [
    "d307bdba37mshafbe7cf23257480p1a6509jsn16f897d20823",
    "82d775c9ecmsh73ca726f3ef3d89p1dd74bjsn9026c0720b5d",
  ];

  /// Get current RapidAPI key (rotate between available keys with better distribution)
  static String get rapidApiKey {
    final now = DateTime.now();
    // Rotate keys every 5 minutes to better distribute API load
    final keyIndex = (now.minute ~/ 5) % rapidApiKeys.length;
    return rapidApiKeys[keyIndex];
  }

  /// Get next available API key (for retry scenarios)
  static String getAlternativeApiKey() {
    final now = DateTime.now();
    // Use different rotation for alternative key
    final keyIndex = ((now.minute ~/ 5) + 1) % rapidApiKeys.length;
    return rapidApiKeys[keyIndex];
  }

  /// Platform-specific API configuration
  static const bool useAlternativeInstagramAPI = true;
  static const bool useAlternativeFacebookAPI = true;
  static const bool useUniversalDownloaderFallback =
      false; // Disabled due to 404 errors
  static const bool useApifyForRedNote =
      false; // Set to true when token is added
  static const bool useDouyinForTikTok =
      true; // Use Douyin API as alternative for TikTok
  static const bool enableDebugLogs = true;
  static const bool enableRetryOnFailure = true;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;

  /// Enhanced API fallback configuration
  static const bool preferBackupAPIs =
      true; // Prefer working backup APIs over main APIs
  static const bool skipFailedAPIs = true; // Skip APIs that return 403 errors
  static const bool enableSmartRetry = true; // Retry with different strategies

  /// Rate limiting and error handling
  static const int rateLimitRetryDelay = 5; // Extra delay for rate limit errors
  static const int maxRateLimitRetries =
      2; // Max retries for rate limited requests

  /// Quality preferences
  static const bool preferHighQuality = true;
  static const bool downloadThumbnails = true;
  static const bool supportImageGalleries = true;

  /// Helper methods
  static bool get isApifyConfigured =>
      apifyApiToken != null && apifyApiToken!.isNotEmpty;

  static bool get shouldUseDouyinApi => useDouyinForTikTok;

  static bool get shouldUseAlternativeInstagramAPI =>
      useAlternativeInstagramAPI;

  static bool get shouldUseAlternativeFacebookAPI => useAlternativeFacebookAPI;

  static bool get shouldUseUniversalFallback => useUniversalDownloaderFallback;

  static bool get shouldPreferBackupAPIs => preferBackupAPIs;

  static bool get shouldSkipFailedAPIs => skipFailedAPIs;

  /// Platform support status
  static Map<String, bool> get platformSupport => {
        'TikTok': true,
        'Instagram': shouldUseAlternativeInstagramAPI,
        'Facebook': shouldUseAlternativeFacebookAPI,
        'YouTube': true,
        'RedNote': isApifyConfigured || true, // Main API may support
        'Douyin': shouldUseDouyinApi,
      };

  /// Instructions for users
  static const String apifyInstructions = '''
To enable enhanced RedNote support with Apify:
1. Go to https://apify.com and create a free account
2. Navigate to Account > Integrations to get your API token
3. Add your token to lib/src/core/utils/api_config.dart
4. Set useApifyForRedNote = true
5. Rebuild the app

Free tier includes:
- 1,000 actor runs per month
- 10GB of data transfer
- Perfect for personal use
''';

  static const String douyinInstructions = '''
Douyin API is enabled for enhanced TikTok support:
- Better video quality extraction
- Support for Douyin (Chinese TikTok) content
- Improved success rate for TikTok downloads
- Auto-fallback to main API if Douyin fails
- No watermark downloads (when available)
''';

  static const String rapidApiKeyInstructions = '''
If you get 403 "not subscribed" errors:
1. Go to https://rapidapi.com and sign up for a free account
2. Subscribe to the required APIs:
   - Social Media Video Downloader
   - TikTok Full Info Without Watermark
   - Instagram Downloader
   - Facebook Video Downloader
3. Get your X-RapidAPI-Key from the API dashboard
4. Update the rapidApiKeys list in lib/src/core/utils/api_config.dart
5. Rebuild the app

The app will automatically fall back to working APIs when possible.
''';

  static const String optimizationTips = '''
Download Optimization Tips:
1. Use Wi-Fi for faster downloads
2. Close other apps during download
3. Enable "Prefer High Quality" for best video quality
4. Allow background downloads in settings
5. Clear app cache if downloads fail repeatedly
6. If you get API errors, the app will try backup methods automatically
''';

  /// Error messages
  static const String networkError =
      "Network connection error. Please check your internet connection.";
  static const String unsupportedPlatform =
      "This platform is not yet supported. We're working on adding support!";
  static const String rateLimitError =
      "Rate limit exceeded. Please wait a moment and try again.";
  static const String invalidUrlError =
      "Invalid URL format. Please check the link and try again.";
  static const String videoNotFound =
      "Video not found or is private. Please check if the content is publicly available.";
  static const String apiSubscriptionError =
      "API subscription required. Please check your API keys.";

  /// Get next API key for rotation
  static String getNextApiKey() {
    final now = DateTime.now();
    final keyIndex = (now.minute ~/ 10) % rapidApiKeys.length;
    return rapidApiKeys[keyIndex];
  }

  /// Check if rate limiting is likely based on time
  static bool shouldDelayRequest() {
    final now = DateTime.now();
    // Avoid peak hours (every 15 minutes for 2 minutes)
    return (now.minute % 15) < 2;
  }
}
