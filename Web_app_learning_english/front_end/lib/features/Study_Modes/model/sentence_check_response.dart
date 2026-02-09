class SentenceCheckResponse {
  final bool isCorrect;
  final String feedback;

  SentenceCheckResponse({required this.isCorrect, required this.feedback});

  factory SentenceCheckResponse.fromJson(Map<String, dynamic> json) {
    return SentenceCheckResponse(
      isCorrect: json['isCorrect'],
      feedback: json['feedback'],
    );
  }
}
