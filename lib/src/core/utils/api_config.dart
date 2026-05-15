class ApiConfig {
  // Cobalt API instances - app tries each in order until one works
  // Add your own self-hosted instance at the top for best reliability
  // Docker: https://github.com/imputnet/cobalt
  static const List<String> cobaltInstances = [
    "http://34.128.84.130:9000",
    "https://api.cobalt.tools",
  ];

  // Cobalt API key (optional - only needed if instance requires auth)
  static const String? cobaltApiKey = null;

  // Cookie sync server - deploy server/cookie_sync.py on VPS
  // URL: http://your-vps-ip:9001  API_KEY: same as in cookie_sync.py
  static const String cookieSyncUrl = "http://34.128.84.130:9005";
  static const String cookieSyncApiKey = "wrIShnwgKDOvpNs7jCj30SweholNPjAo";

  // yt-dlp API - YouTube fallback (deploy server/ytdlp_api.py on VPS)
  static const String ytdlpApiUrl = "http://34.128.84.130:9002";
  static const String ytdlpApiKey = "wrIShnwgKDOvpNs7jCj30SweholNPjAo";

  // TikWM fallback for TikTok (free, no auth)
  static const bool useTikwmFallback = true;

  // Video quality preference sent to Cobalt
  static const String videoQuality = "1080";

  // Download settings
  static const bool enableRetryOnFailure = true;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;
  static const bool enableDebugLogs = true;

  // Quality preferences
  static const bool preferHighQuality = true;
  static const bool supportImageGalleries = true;

  // Error messages
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
  static const String allApisFailed =
      "All download services failed. Try again later or use a different link.";
}
