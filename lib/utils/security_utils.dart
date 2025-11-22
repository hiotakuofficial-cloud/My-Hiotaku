import 'dart:convert';
import 'dart:math';

class SecurityUtils {
  // Generate secure headers for API requests
  static Map<String, String> getSecureHeaders({String? apiKey}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': 'HiotakuApp/1.0',
      'Accept': 'application/json',
    };
    
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    
    // Add timestamp for request validation
    headers['X-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
    
    return headers;
  }
  
  // Validate API response
  static bool isValidResponse(Map<String, dynamic> response) {
    return response.containsKey('success') && 
           response['success'] is bool;
  }
  
  // Sanitize user input
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"\']'), '')
        .trim()
        .substring(0, input.length > 100 ? 100 : input.length);
  }
  
  // Generate request ID for tracking
  static String generateRequestId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(999999);
    return '${timestamp}_$randomNum';
  }
}
