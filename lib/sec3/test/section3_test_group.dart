import 'package:flutter/foundation.dart';
import 'dart:convert';

class Section3TestGroup {
  final int groupId;
  final String groupName;
  final String groupNameEnglish;
  final int sessionId;
  final int level;
  final List<Section3TestDetail> details;

  Section3TestGroup({
    required this.groupId,
    required this.groupName,
    required this.groupNameEnglish,
    required this.sessionId,
    required this.level,
    required this.details,
  });

  factory Section3TestGroup.fromJson(Map<String, dynamic> json) {
    var detailsList = <Section3TestDetail>[];
    if (json['details'] != null && json['details']['\$values'] != null) {
      detailsList = (json['details']['\$values'] as List)
          .map((item) => Section3TestDetail.fromJson(item))
          .toList();
    }
    return Section3TestGroup(
      groupId: json['groupId'] ?? 0,
      groupName: json['groupName'] ?? '',
      groupNameEnglish: json['groupNameEnglish'] ?? '',
      sessionId: json['sessionId'] ?? 0,
      level: json['level'] ?? 0,
      details: detailsList,
    );
  }
}

class Section3TestDetail {
  final int detailId;
  final String? videoUrl;
  final String? question;
  final String rightAnswer;
  final String? more;
  final List<String> answerOptions;

  Section3TestDetail({
    required this.detailId,
    this.videoUrl,
    this.question,
    required this.rightAnswer,
    this.more,
    required this.answerOptions,
  });

  factory Section3TestDetail.fromJson(Map<String, dynamic> json) {
    List<String> options = [];
    if (json['answers'] is String) {
      options = (json['answers'] as String).split(' - ').map((e) => e.trim()).toList();
    }
    return Section3TestDetail(
      detailId: json['detail_ID'] ?? 0,
      videoUrl: json['video'],
      question: json['question'],
      rightAnswer: json['rightAnswer'] ?? '',
      more: json['more'],
      answerOptions: options,
    );
  }
}