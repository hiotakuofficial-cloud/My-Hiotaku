class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  // Notification types
  static const String mergeRequest = 'merge_request';
  static const String mergeAccepted = 'merge_accepted';
  static const String mergeRejected = 'merge_rejected';
  static const String mergeExpired = 'merge_expired';

  // Create merge request notification
  static NotificationModel createMergeRequest({
    required String requestId,
    required String senderName,
    required String senderUsername,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Merge Request',
      body: '$senderUsername sent a request to see your favourites. Approve to continue.',
      type: mergeRequest,
      data: {
        'request_id': requestId,
        'sender_name': senderName,
        'sender_username': senderUsername,
        'action_required': true,
      },
      timestamp: DateTime.now(),
    );
  }

  // Create merge accepted notification
  static NotificationModel createMergeAccepted({
    required String receiverName,
    required String receiverUsername,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Merge Request Accepted! 🎉',
      body: '$receiverName (@$receiverUsername) accepted your merge request',
      type: mergeAccepted,
      data: {
        'receiver_name': receiverName,
        'receiver_username': receiverUsername,
        'action_required': false,
      },
      timestamp: DateTime.now(),
    );
  }

  // Create merge rejected notification
  static NotificationModel createMergeRejected({
    required String receiverName,
    required String receiverUsername,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Merge Request Declined',
      body: '$receiverName (@$receiverUsername) declined your merge request',
      type: mergeRejected,
      data: {
        'receiver_name': receiverName,
        'receiver_username': receiverUsername,
        'action_required': false,
      },
      timestamp: DateTime.now(),
    );
  }

  // Create merge expired notification
  static NotificationModel createMergeExpired({
    required String senderName,
    required String senderUsername,
  }) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Merge Request Expired ⏰',
      body: 'Your merge request to $senderName (@$senderUsername) has expired',
      type: mergeExpired,
      data: {
        'sender_name': senderName,
        'sender_username': senderUsername,
        'action_required': false,
      },
      timestamp: DateTime.now(),
    );
  }
}
