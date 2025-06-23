import 'package:flutter/foundation.dart';

enum NotificationType {
  sessionEnded,
  sessionUpcoming,
  sessionReady,
  monthlyTestAvailable,
  threeMonthTestAvailable,
  systemMessage, // <-- *** أضف هذا السطر ***
}

class NotificationItem {
  final String id;
  final String title;
  final DateTime createdAt;
  final NotificationType type;
  bool isActive;
  bool isRead;

  String get timeAgoDisplay => formatTimeAgo(createdAt);

  NotificationItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.type,
    this.isActive = true,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'type': type.toString(),
    'isActive': isActive,
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = DateTime.parse(json['createdAt'] as String);
    } catch (e) {
      debugPrint("Error parsing createdAt from JSON: ${json['createdAt']}. Using DateTime.now(). Error: $e");
      parsedCreatedAt = DateTime.now();
    }

    NotificationType parsedType;
    try {
      parsedType = NotificationType.values.firstWhere(
            (e) => e.toString() == json['type'] as String,
        orElse: () {
            debugPrint("Warning: Unknown notification type '${json['type']}'. Defaulting to sessionReady.");
            return NotificationType.sessionReady;
        });
    } catch (e) {
      debugPrint("Error parsing notification type from JSON: ${json['type']}. Error: $e");
      parsedType = NotificationType.sessionReady;
    }

    return NotificationItem(
      id: json['id'] as String? ?? 'unknown_id_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'إشعار غير معنون',
      createdAt: parsedCreatedAt,
      type: parsedType,
      isActive: json['isActive'] as bool? ?? true,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

String formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 5) { return "الآن"; }
  if (difference.inSeconds < 60) { return "${difference.inSeconds} ث"; }
  if (difference.inMinutes < 60) { return "${difference.inMinutes} د"; }
  if (difference.inHours < 24) { return "${difference.inHours} س"; }
  if (difference.inDays < 7) { return "${difference.inDays} ي"; }
  if (difference.inDays < 30) { return "${(difference.inDays / 7).floor()} أ"; }
  if (difference.inDays < 365) { return "${(difference.inDays / 30).floor()} ش"; }
  return "${(difference.inDays / 365).floor()} سنة";
}