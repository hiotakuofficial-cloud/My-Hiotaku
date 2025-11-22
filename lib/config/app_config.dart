class AppConfig {
  // Use environment variables or secure storage in production
  static const String _baseUrl = String.fromEnvironment('API_BASE_URL', 
    defaultValue: 'YOUR_API_ENDPOINT_HERE');
  
  static String get baseUrl => _baseUrl;
  
  // Add API key if needed
  static const String _apiKey = String.fromEnvironment('API_KEY', 
    defaultValue: '');
  
  static String get apiKey => _apiKey;
}
