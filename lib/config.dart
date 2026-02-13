class AppConfig {
  // API Configuration - Environment Variables
  static const String animeApiBaseUrl = String.fromEnvironment('API_URL');
  static const String animeApiEndpoint = '/api.php';
  static const String hindiApiEndpoint = '/hindiv2.php';
  
  // App signature hash - Environment Variable
  static const String app_hash_base256 = String.fromEnvironment('API_TOKEN');
  
  // App Configuration
  static const String appName = 'Hiotaku';
  static const String appVersion = '1.0.1+2';
  
  // Cache Configuration
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100;
  
  // Network Configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  
  // Get authenticated token
  static String get apiToken => app_hash_base256;
  
  // Headers with authentication
  static Map<String, String> get defaultHeaders => {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/91.0.4472.120 Mobile Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept-Encoding': 'identity', // Disable compression
    'Connection': 'keep-alive',
    'Referer': 'https://www.youtube.com/',
    'Authorization': 'Bearer $app_hash_base256',
  };
  
  // API Endpoints
  static String get homeEndpoint => '$animeApiBaseUrl$animeApiEndpoint';
  static String get searchEndpoint => '$animeApiBaseUrl$animeApiEndpoint';
  static String get detailsEndpoint => '$animeApiBaseUrl$animeApiEndpoint';
  static String get hindiApiUrl => '$animeApiBaseUrl$hindiApiEndpoint';
  static String get notificationEndpoint => '$animeApiBaseUrl/notification/api/send.php?token=$app_hash_base256';
  
  // Build URL with parameters and token
  static String buildUrl(String action, Map<String, dynamic> params) {
    final allParams = Map<String, dynamic>.from(params);
    allParams['action'] = action;
    allParams['token'] = app_hash_base256; // Add token to URL params
    
    final queryParams = allParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    
    return '$animeApiBaseUrl$animeApiEndpoint?$queryParams';
  }
  
  // Build Hindi API URL
  static String buildHindiUrl(String action, Map<String, dynamic> params) {
    final allParams = Map<String, dynamic>.from(params);
    allParams['action'] = action;
    allParams['token'] = app_hash_base256;
    
    final queryParams = allParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    
    return '$animeApiBaseUrl$hindiApiEndpoint?$queryParams';
  }
  
  // Notification API Headers
  static Map<String, String> get notificationHeaders => {
    'Content-Type': 'application/json',
    'Authorization': app_hash_base256,
  };
}
