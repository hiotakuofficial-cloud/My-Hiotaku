class DataValidator {
  // User validation
  static bool isValidEmail(String email) {
    try {
      return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidUsername(String username) {
    try {
      return username.length >= 3 && 
             username.length <= 30 && 
             RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidUserId(String userId) {
    try {
      return userId.isNotEmpty && userId.length <= 100;
    } catch (e) {
      return false;
    }
  }
  
  // Anime validation
  static bool isValidAnimeId(String animeId) {
    try {
      return animeId.isNotEmpty && animeId.length <= 50;
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidAnimeTitle(String title) {
    try {
      return title.isNotEmpty && title.length <= 200;
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidImageUrl(String? url) {
    try {
      if (url == null || url.isEmpty) return true; // Optional field
      return Uri.tryParse(url) != null && url.length <= 500;
    } catch (e) {
      return false;
    }
  }
  
  // Pagination validation
  static int validatePage(int? page) {
    try {
      if (page == null || page < 1) return 1;
      if (page > 1000) return 1000; // Max page limit
      return page;
    } catch (e) {
      return 1;
    }
  }
  
  static int validateLimit(int? limit) {
    try {
      if (limit == null || limit < 1) return 20;
      if (limit > 100) return 100; // Max limit
      return limit;
    } catch (e) {
      return 20;
    }
  }
  
  // Search query validation
  static String? validateSearchQuery(String? query) {
    try {
      if (query == null || query.trim().isEmpty) return null;
      String cleaned = query.trim();
      if (cleaned.length > 100) return cleaned.substring(0, 100);
      return cleaned;
    } catch (e) {
      return null;
    }
  }
  
  // Sanitize user input
  static String sanitizeString(String input) {
    try {
      return input.trim()
          .replaceAll('<', '')
          .replaceAll('>', '')
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll('`', '')
          .replaceAll(RegExp(r'\s+'), ' ');
    } catch (e) {
      return '';
    }
  }
  
  // Validate favorite data
  static Map<String, dynamic>? validateFavoriteData({
    required String userId,
    required String animeId,
    required String animeTitle,
    String? animeImage,
    bool? isPublic,
  }) {
    try {
      if (!isValidUserId(userId)) return null;
      if (!isValidAnimeId(animeId)) return null;
      if (!isValidAnimeTitle(animeTitle)) return null;
      if (!isValidImageUrl(animeImage)) return null;
      
      return {
        'user_id': userId,
        'anime_id': sanitizeString(animeId),
        'anime_title': sanitizeString(animeTitle),
        'anime_image': animeImage?.trim(),
        'is_public': isPublic ?? false,
        'added_at': DateTime.now().toIso8601String(), // Fixed: created_at → added_at
      };
    } catch (e) {
      return null;
    }
  }
  
  // Validate user data
  static Map<String, dynamic>? validateUserData({
    required String firebaseUID,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? username,
  }) {
    try {
      if (!isValidUserId(firebaseUID)) return null;
      if (!isValidEmail(email)) return null;
      if (username != null && !isValidUsername(username)) return null;
      if (!isValidImageUrl(avatarUrl)) return null;
      
      return {
        'firebase_uid': firebaseUID,
        'email': email.toLowerCase().trim(),
        'display_name': displayName?.trim(),
        'avatar_url': avatarUrl?.trim(),
        'username': username?.toLowerCase().trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }
  
  // Validate merge request data
  static Map<String, dynamic>? validateMergeRequestData({
    required String senderId,
    required String receiverId,
    String? message,
  }) {
    try {
      if (!isValidUserId(senderId)) return null;
      if (!isValidUserId(receiverId)) return null;
      if (senderId == receiverId) return null; // Can't merge with self
      
      String cleanMessage = message?.trim() ?? 'Sync request';
      if (cleanMessage.length > 200) {
        cleanMessage = cleanMessage.substring(0, 200);
      }
      
      return {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': sanitizeString(cleanMessage),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }
  
  // Validate database response
  static List<Map<String, dynamic>> validateDatabaseResponse(dynamic response) {
    try {
      if (response == null) return [];
      if (response is List) {
        return response
            .where((item) => item is Map<String, dynamic>)
            .cast<Map<String, dynamic>>()
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // Rate limiting validation
  static bool isWithinRateLimit(DateTime? lastAction, Duration minInterval) {
    try {
      if (lastAction == null) return true;
      return DateTime.now().difference(lastAction) >= minInterval;
    } catch (e) {
      return true; // Allow on error
    }
  }
}
