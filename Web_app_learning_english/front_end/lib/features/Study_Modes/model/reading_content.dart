class ReadingContent {
  final String story;
  final List<ReadingQuestion> questions;

  ReadingContent({required this.story, required this.questions});

  factory ReadingContent.fromJson(Map<String, dynamic> json) {
    var questionsList = json['questions'] as List? ?? [];
    List<ReadingQuestion> questions =
        questionsList.map((i) => ReadingQuestion.fromJson(i)).toList();

    return ReadingContent(
      story: json['story'] ?? 'Không có nội dung bài đọc.',
      questions: questions,
    );
  }
}

class ReadingQuestion {
  final String question;
  final List<String> options;
  final String answer;

  ReadingQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory ReadingQuestion.fromJson(Map<String, dynamic> json) {
    final optionsList = json['options'] as List? ?? [];
    final List<String> safeOptions =
        optionsList.map((option) => option.toString()).toList();
    final String safeAnswer = json['answer']?.toString() ?? '';

    return ReadingQuestion(
      question: json['question'] ?? 'Câu hỏi không có nội dung.',
      options: safeOptions,
      answer: safeAnswer,
    );
  }
}
