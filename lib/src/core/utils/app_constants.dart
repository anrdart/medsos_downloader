class AppConstants {
  static const String baseUrl =
      "https://social-media-video-downloader.p.rapidapi.com";
  static const String getVideoEndpoint = "/smvd/get/all";

  // Alternative API for Facebook and Instagram
  static const String socialDownloaderBaseUrl =
      "https://instagram-downloader-download-instagram-videos-stories.p.rapidapi.com";
  static const String instagramEndpoint = "/";

  static const String facebookDownloaderBaseUrl =
      "https://facebook-video-downloader.p.rapidapi.com";
  static const String facebookEndpoint = "/facebook";

  // Xiaohongshu-specific API (much better for RedNote)
  static const String xiaohongshuBaseUrl =
      "https://xiaohongshu-all-api.p.rapidapi.com";
  static const String xiaohongshuEndpoint =
      "/api/xiaohongshu/get-note-detail/v6";
  static const String xiaohongshuApiKey =
      "82d775c9ecmsh73ca726f3ef3d89p1dd74bjsn9026c0720b5d";
  static const String xiaohongshuApiHost = "xiaohongshu-all-api.p.rapidapi.com";

  // Douyin API Configuration (Fixed host reference)
  static const String douyinBaseUrl = "https://douyin-api-new.p.rapidapi.com";
  static const String douyinVideoEndpoint = "/v1/social/douyin/app/video/info";
  static const String douyinSearchEndpoint =
      "/v1/social/douyin/app/search/video";
  static const String douyinApiKey =
      "82d775c9ecmsh73ca726f3ef3d89p1dd74bjsn9026c0720b5d";
  static const String douyinApiHost = "douyin-api-new.p.rapidapi.com";

  // Alternative Douyin APIs (for fallback like RedNote)
  static const String douyinAltBaseUrl =
      "https://tiktok-full-info-without-watermark.p.rapidapi.com";
  static const String douyinAltEndpoint = "/";
  static const String douyinAltApiHost =
      "tiktok-full-info-without-watermark.p.rapidapi.com";

  // Douyin Backup API (Chinese API - working for demo)
  static const String douyinBackupBaseUrl = "https://api.douyin.wtf";
  static const String douyinBackupEndpoint = "/api/hybrid/video_data";

  // User post endpoint (as additional fallback)
  static const String douyinUserPostEndpoint =
      "/v1/social/douyin/app/user/post";

  // Universal downloader API - Commented out as it's currently returning 404
  // static const String universalDownloaderBaseUrl =
  //     "https://all-in-one-downloader.p.rapidapi.com";
  // static const String universalDownloaderEndpoint = "/download";

  // Alternative TikTok/Douyin API (for fallback)
  static const String alternativeTikTokBaseUrl = "https://www.52api.cn";
  static const String alternativeTikTokEndpoint = "/api/douyin";

  // Backup TikTok API
  static const String backupTikTokBaseUrl =
      "https://tiktok-video-no-watermark2.p.rapidapi.com";
  static const String backupTikTokEndpoint = "/";

  // Apify API for RedNote (Xiaohongshu) - Most reliable option
  static const String apifyBaseUrl = "https://api.apify.com/v2";
  static const String apifyRedNoteActor =
      "easyapi~rednote-xiaohongshu-video-downloader";
  static const String apifyRunEndpoint =
      "/acts/{actorId}/run-sync-get-dataset-items";

  // Alternative API for RedNote (based on vnil.cn concept)
  static const String vnilBaseUrl = "https://vnil.com";
  static const String vnilApiUrl = "https://api.vnil.com";

  static const int navigateTime = 3000;
  static const int animationTime = 2000;
  static final int socialPlatformsCount = SocialPlatform.values.length;
}

enum SocialPlatform { tiktok, instagram, snapchat, youtube, facebook, rednote }
