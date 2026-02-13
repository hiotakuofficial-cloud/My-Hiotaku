import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class NotificationService {
  
  /// Send notification to specific user
  static Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String screen = '/main',
    String? animeId,
    int? episodeNumber,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'screen': screen,
        'send_type': 'specific',
      };
      
      // Add optional fields
      if (animeId != null) payload['anime_id'] = animeId;
      if (episodeNumber != null) payload['episode_number'] = episodeNumber.toString();
      if (extraData != null) {
        extraData.forEach((key, value) {
          payload[key] = value.toString();
        });
      }
      
      final response = await http.post(
        Uri.parse(AppConfig.notificationEndpoint),
        headers: AppConfig.notificationHeaders,
        body: jsonEncode(payload),
      ).timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Send broadcast notification to all users
  static Future<bool> sendBroadcast({
    required String title,
    required String body,
    String type = 'announcement',
    String screen = '/main',
    String? animeId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final payload = {
        'title': title,
        'body': body,
        'type': type,
        'screen': screen,
        'send_type': 'all',
      };
      
      // Add optional fields
      if (animeId != null) payload['anime_id'] = animeId;
      if (extraData != null) {
        extraData.forEach((key, value) {
          payload[key] = value.toString();
        });
      }
      
      final response = await http.post(
        Uri.parse(AppConfig.notificationEndpoint),
        headers: AppConfig.notificationHeaders,
        body: jsonEncode(payload),
      ).timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Quick notification methods for common use cases
  
  // Welcome new user
  static Future<bool> sendWelcome(String userId) {
    return sendNotification(
      userId: userId,
      title: 'Welcome to ${AppConfig.appName}',
      body: 'Start exploring amazing anime series and movies available on our platform.',
      type: 'general',
      screen: '/main',
    );
  }
  
  // New anime added
  static Future<bool> sendNewAnime({
    required String userId,
    required String animeTitle,
    required String animeId,
  }) {
    return sendNotification(
      userId: userId,
      title: 'New Anime Added',
      body: '$animeTitle is now available on ${AppConfig.appName}. Watch now!',
      type: 'new_anime',
      screen: '/details',
      animeId: animeId,
    );
  }
  
  // New episode available
  static Future<bool> sendNewEpisode({
    required String userId,
    required String animeTitle,
    required String animeId,
    required int episodeNumber,
  }) {
    return sendNotification(
      userId: userId,
      title: 'New Episode Available',
      body: '$animeTitle Episode $episodeNumber is now streaming.',
      type: 'new_episode',
      screen: '/details',
      animeId: animeId,
      episodeNumber: episodeNumber,
    );
  }
  
  // Reminder to continue watching
  static Future<bool> sendWatchReminder(String userId) {
    return sendNotification(
      userId: userId,
      title: 'Continue Watching',
      body: 'Resume your favorite anime series and discover new episodes.',
      type: 'reminder',
      screen: '/favourite',
    );
  }
  
  // App update notification
  static Future<bool> sendAppUpdate() {
    return sendBroadcast(
      title: 'App Update Available',
      body: 'New version of ${AppConfig.appName} is available with improved features and performance.',
      type: 'update',
      screen: '/profile',
    );
  }
}
