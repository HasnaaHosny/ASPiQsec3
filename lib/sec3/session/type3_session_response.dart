class Type3SessionResponse {
  final int sessionId;
  final String? sessionTitle;
  final String? sessionDescription;
  final List<Type3SessionDetail> details;

  Type3SessionResponse({
    required this.sessionId,
    this.sessionTitle,
    this.sessionDescription,
    required this.details,
  });

  factory Type3SessionResponse.fromJson(Map<String, dynamic> json) {
    var detailsList = <Type3SessionDetail>[];
    if (json['details'] != null && json['details']['\$values'] != null) {
      detailsList = (json['details']['\$values'] as List)
          .map((item) => Type3SessionDetail.fromJson(item))
          .toList();
    }

    return Type3SessionResponse(
      // --- *** التأكد من أن كل الحقول هنا بحرف صغير *** ---
      sessionId: json['sessionId'] ?? 0,
      sessionTitle: json['sessionTitle'],
      sessionDescription: json['sessionDescription'],
      details: detailsList,
    );
  }
}

class Type3SessionDetail {
  final int id;
  final String? dataTypeOfContent;
  final String? videoUrl;
  final String? text;

  Type3SessionDetail({
    required this.id,
    this.dataTypeOfContent,
    this.videoUrl,
    this.text,
  });

  factory Type3SessionDetail.fromJson(Map<String, dynamic> json) {
    return Type3SessionDetail(
      id: json['id'] ?? 0,
      dataTypeOfContent: json['dataTypeOfContent'],
      videoUrl: json['video'],
      text: json['text_'],
    );
  }
}