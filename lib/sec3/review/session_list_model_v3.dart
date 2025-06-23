import 'dart:convert';
import 'package:flutter/foundation.dart';

// ... (دالة sessionsV3FromJson تبقى كما هي)
List<SessionV3> sessionsV3FromJson(String str) {
  try {
    final jsonData = jsonDecode(str);
    if (jsonData is Map && jsonData.containsKey('\$values') && jsonData['\$values'] is List) {
      final List rawList = jsonData['\$values'];
      return List<SessionV3>.from(rawList.map((x) => SessionV3.fromJson(x as Map<String, dynamic>)));
    }
    return [];
  } catch (e) {
    debugPrint("[sessionsV3FromJson] Error decoding JSON: $e");
    return [];
  }
}

// ... (كلاس SessionV3 و SessionDetailsV3 تبقى كما هي)
class SessionV3 {
  final int? sessionId;
  final String title;
  final bool isOpen;
  final SessionDetailsV3 details;

  SessionV3({
    this.sessionId,
    required this.title,
    required this.isOpen,
    required this.details,
  });

  factory SessionV3.fromJson(Map<String, dynamic> json) {
    return SessionV3(
      sessionId: json['session_ID_'],
      title: json['title'] ?? 'جلسة غير معنونة',
      isOpen: json['isOpen'] ?? false,
      details: SessionDetailsV3.fromJson(json['details'] ?? {'\$values': []}),
    );
  }
}

class SessionDetailsV3 {
  final List<DetailItemV3> values;
  SessionDetailsV3({required this.values});

  factory SessionDetailsV3.fromJson(Map<String, dynamic> json) {
    var valuesList = <DetailItemV3>[];
    if (json['\$values'] != null && json['\$values'] is List) {
      valuesList = List<DetailItemV3>.from(
          (json['\$values'] as List).map((x) => DetailItemV3.fromJson(x as Map<String, dynamic>)));
    }
    return SessionDetailsV3(values: valuesList);
  }
}

// --- *** بداية التعديل هنا *** ---
class DetailItemV3 {
  // 1. إضافة حقل ID
  final int id; 
  final String dataTypeOfContent;
  final String? videoUrl;
  final String? text;
  final String? description;

  DetailItemV3({
    required this.id, // 2. جعله مطلوبًا
    required this.dataTypeOfContent,
    this.videoUrl,
    this.text,
    this.description,
  });

  factory DetailItemV3.fromJson(Map<String, dynamic> json) {
    // 3. استخراج الـ ID من '$id' وتحويله إلى int
    // إذا فشل التحويل، نستخدم قيمة فريدة عشوائية كحل بديل
    final int parsedId = int.tryParse(json['\$id']?.toString() ?? '') ?? DateTime.now().microsecondsSinceEpoch;

    return DetailItemV3(
      id: parsedId, // 4. تعيين قيمة الـ ID
      dataTypeOfContent: json['dataTypeOfContent'] ?? 'Unknown',
      videoUrl: json['video'],
      text: json['text_'],
      description: json['desc'],
    );
  }
}
// --- *** نهاية التعديل هنا *** ---