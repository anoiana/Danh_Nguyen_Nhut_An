class ListeningContent {
  final String transcript;
  final List<ListeningMCQ> mcq;
  final ListeningFITB fitb;

  ListeningContent({
    required this.transcript,
    required this.mcq,
    required this.fitb,
  });

  factory ListeningContent.fromJson(Map<String, dynamic> json) {
    var mcqList = json['mcq'] as List? ?? [];
    List<ListeningMCQ> mcqs =
        mcqList.map((i) => ListeningMCQ.fromJson(i)).toList();

    return ListeningContent(
      transcript: json['transcript'] ?? 'Không có nội dung.',
      mcq: mcqs,
      fitb: ListeningFITB.fromJson(json['fitb'] ?? {}),
    );
  }
}

class ListeningMCQ {
  final String question;
  final List<String> options;
  final String answer;

  ListeningMCQ({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory ListeningMCQ.fromJson(Map<String, dynamic> json) {
    return ListeningMCQ(
      question: json['question'] ?? 'Câu hỏi không có nội dung.',
      options: List<String>.from(json['options'] ?? []),
      answer: json['answer'] ?? '',
    );
  }
}

class ListeningFITB {
  final String textWithBlanks;
  final List<String> answers;

  ListeningFITB({required this.textWithBlanks, required this.answers});

  factory ListeningFITB.fromJson(Map<String, dynamic> json) {
    return ListeningFITB(
      textWithBlanks: json['textWithBlanks'] ?? '',
      answers: List<String>.from(json['answers'] ?? []),
    );
  }
}
