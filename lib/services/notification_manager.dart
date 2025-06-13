// lib/services/notification_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationManager {
  static const String _notificationsKey =
      'app_notifications_list_v4'; // <-- تم تحديث الإصدار بسبب isRead
  static const String _monthlyTestNotifSentKey =
      'monthly_test_notif_sent_flag_v2';
  static const String _threeMonthTestNotifSentKey =
      'three_month_test_notif_sent_flag_v2';

  static final AudioPlayer _audioPlayer = AudioPlayer(); // <-- إضافة جديدة
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> _playNotificationSound() async {
    // <-- إضافة جديدة
    try {
      // تأكدي أن المسار صحيح وأن الملف موجود في assets/audio/
      await _audioPlayer.play(AssetSource('audio/notification.mp3'));
      debugPrint("NotificationManager: Played notification sound.");
    } catch (e) {
      debugPrint("NotificationManager: Error playing sound: $e");
    }
  }

  static Future<List<NotificationItem>> _loadAllNotificationsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? notificationsJsonList =
        prefs.getStringList(_notificationsKey);
    if (notificationsJsonList == null || notificationsJsonList.isEmpty)
      return [];
    List<NotificationItem> allItems = [];
    for (String jsonString in notificationsJsonList) {
      try {
        if (jsonString.trim().isNotEmpty) {
          allItems.add(NotificationItem.fromJson(jsonDecode(jsonString)));
        }
      } catch (e) {
        debugPrint(
            "NotificationManager: Error parsing item: $e. Item: $jsonString");
      }
    }
    return allItems;
  }

  static Future<List<NotificationItem>> loadActiveNotifications() async {
    List<NotificationItem> allNotifications = await _loadAllNotificationsRaw();
    return allNotifications.where((item) => item.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> _saveNotifications(
      List<NotificationItem> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notificationsJsonList =
        notifications.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_notificationsKey, notificationsJsonList);
    debugPrint(
        "NotificationManager: Saved ${notifications.length} total notifications.");
  }

  static Future<void> initializeLocalNotifications() async {
    // Request notification permissions
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Request permissions for Android 13 and above
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_stat_logo');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> _showDeviceNotification(NotificationItem item) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'app_channel_id',
        'App Notifications',
        channelDescription: 'Notifications from the app',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: 'ic_stat_logo', // Use the custom notification icon
      );
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(); // iOS uses app icon by default
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique notification id
        item.title,
        null, // or a subtitle/message
        platformChannelSpecifics,
      );
      debugPrint(
          'NotificationManager: Device notification sent for: \'${item.title}\'');
    } catch (e, s) {
      debugPrint('NotificationManager: ERROR sending device notification: $e');
      debugPrint('Stacktrace: $s');
    }
  }

  static Future<void> addOrUpdateNotification(NotificationItem newItem,
      {bool playSound = true}) async {
    List<NotificationItem> currentNotifications =
        await _loadAllNotificationsRaw();
    int existingIndexById =
        currentNotifications.indexWhere((n) => n.id == newItem.id);

    bool isTrulyNew = false;

    if (newItem.type == NotificationType.sessionEnded ||
        newItem.type == NotificationType.sessionUpcoming ||
        newItem.type == NotificationType.sessionReady) {
      for (int i = 0; i < currentNotifications.length; i++) {
        if (currentNotifications[i].type == newItem.type &&
            currentNotifications[i].id != newItem.id) {
          currentNotifications[i].isActive = false;
        }
      }
    }

    newItem.isActive = true;

    if (existingIndexById != -1) {
      // Only update the notification, do not play sound
      newItem.isRead = false;
      currentNotifications[existingIndexById] = newItem;
      debugPrint(
          "NotificationManager: Updated notification by ID: '${newItem.id}', Title='${newItem.title}', IsRead=${newItem.isRead}");
      isTrulyNew = false;
    } else {
      // Only play sound if this is a truly new notification (ID did not exist before)
      newItem.isRead = false;
      currentNotifications.add(newItem);
      debugPrint(
          "NotificationManager: Added new notification: ID='${newItem.id}', Title='${newItem.title}', IsRead=${newItem.isRead}");
      isTrulyNew = true;
    }
    await _saveNotifications(currentNotifications);

    if (playSound && isTrulyNew && newItem.isActive) {
      _playNotificationSound();
      _showDeviceNotification(newItem);
    }
  }

  static Future<void> deactivateNotificationsByType(
      NotificationType typeToDeactivate) async {
    List<NotificationItem> currentNotifications =
        await _loadAllNotificationsRaw();
    bool changed = false;
    for (int i = 0; i < currentNotifications.length; i++) {
      if (currentNotifications[i].type == typeToDeactivate &&
          currentNotifications[i].isActive) {
        currentNotifications[i].isActive = false;
        // currentNotifications[i].isRead = true; // يمكن اعتباره مقروءًا عند إلغاء التنشيط
        changed = true;
        debugPrint(
            "NotificationManager: Deactivated type $typeToDeactivate, ID: ${currentNotifications[i].id}");
      }
    }
    if (changed) await _saveNotifications(currentNotifications);
  }

  // ---!!! وظائف جديدة !!!---
  static Future<void> markNotificationAsRead(String notificationId) async {
    List<NotificationItem> currentNotifications =
        await _loadAllNotificationsRaw();
    int index = currentNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !currentNotifications[index].isRead) {
      currentNotifications[index].isRead = true;
      await _saveNotifications(currentNotifications);
      debugPrint(
          "NotificationManager: Marked notification '${notificationId}' as read.");
    }
  }

  static Future<void> markAllActiveNotificationsAsRead() async {
    List<NotificationItem> currentNotifications =
        await _loadAllNotificationsRaw();
    bool changed = false;
    for (var notification in currentNotifications) {
      if (notification.isActive && !notification.isRead) {
        notification.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      await _saveNotifications(currentNotifications);
      debugPrint(
          "NotificationManager: Marked all active notifications as read.");
    }
  }

  static Future<void> dismissNotification(String notificationId) async {
    List<NotificationItem> currentNotifications =
        await _loadAllNotificationsRaw();
    int index = currentNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && currentNotifications[index].isActive) {
      currentNotifications[index].isActive = false; // فقط اجعله غير نشط
      currentNotifications[index].isRead = true; // واجعله مقروءًا
      await _saveNotifications(currentNotifications);
      debugPrint(
          "NotificationManager: Dismissed (deactivated) notification '${notificationId}'.");
    }
  }
  // ---!!! نهاية الوظائف الجديدة !!!---

  static Future<void> clearSessionStatusNotifications() async {
    List<NotificationItem> currentNotifications =
        await _loadAllNotificationsRaw();
    int originalCount = currentNotifications.length;
    currentNotifications.removeWhere((item) =>
        item.type == NotificationType.sessionEnded ||
        item.type == NotificationType.sessionUpcoming ||
        item.type == NotificationType.sessionReady);
    if (currentNotifications.length < originalCount) {
      await _saveNotifications(currentNotifications);
      debugPrint("NotificationManager: Cleared session status notifications.");
    }
  }

  static Future<bool> isMonthlyTestNotificationSent() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_monthlyTestNotifSentKey) ?? false;
  }

  static Future<void> setMonthlyTestNotificationSent(bool sent) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_monthlyTestNotifSentKey, sent);
    debugPrint("NotificationManager: Monthly flag set to $sent");
  }

  static Future<bool> isThreeMonthTestNotificationSent() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_threeMonthTestNotifSentKey) ?? false;
  }

  static Future<void> setThreeMonthTestNotificationSent(bool sent) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_threeMonthTestNotifSentKey, sent);
    debugPrint("NotificationManager: 3-Month flag set to $sent");
  }

  static Future<void> clearAllNotificationsAndFlagsForDebugging() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
    await prefs.remove(_monthlyTestNotifSentKey);
    await prefs.remove(_threeMonthTestNotifSentKey);
    _audioPlayer.dispose(); // <-- تنظيف مشغل الصوت عند مسح كل شيء
    debugPrint(
        "NotificationManager: DEBUG - All notifications and flags cleared.");
  }
}
