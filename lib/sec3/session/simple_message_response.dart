class SimpleMessageResponse {
  final String message;
  final int? sessionId;
  final String? sessionTitle;

  SimpleMessageResponse({required this.message, this.sessionId, this.sessionTitle});

  factory SimpleMessageResponse.fromJson(Map<String, dynamic> json) {
    return SimpleMessageResponse(
      // --- *** التصحيح هنا *** ---
      message: json['message'] as String? ?? 'رسالة غير معروفة من الخادم.',
      sessionId: json['sessionId'] as int?,
      sessionTitle: json['sessionTitle'] as String?,
    );
  }
}