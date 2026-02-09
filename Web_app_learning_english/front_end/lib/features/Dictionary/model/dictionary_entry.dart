class Definition {
  final String definition;
  final String? example;

  const Definition({required this.definition, this.example});

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(definition: json['definition'], example: json['example']);
  }
}

class Meaning {
  final String partOfSpeech;
  final List<Definition> definitions;
  final List<String> synonyms;
  final List<String> antonyms;

  const Meaning({
    required this.partOfSpeech,
    required this.definitions,
    required this.synonyms,
    required this.antonyms,
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      partOfSpeech: json['partOfSpeech'],
      definitions:
          (json['definitions'] as List)
              .map((d) => Definition.fromJson(d))
              .toList(),
      synonyms: List<String>.from(json['synonyms'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
    );
  }
}

class DictionaryEntry {
  final String word;
  final String? phonetic;
  final String? audioUrl;
  final List<Meaning> meanings;

  const DictionaryEntry({
    required this.word,
    this.phonetic,
    this.audioUrl,
    required this.meanings,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    String? audio = '';
    if (json['phonetics'] != null && (json['phonetics'] as List).isNotEmpty) {
      final phoneticsList = json['phonetics'] as List;
      final audioItem = phoneticsList.firstWhere(
        (p) => p['audio'] != null && p['audio'] != '',
        orElse: () => null,
      );
      if (audioItem != null) {
        audio = audioItem['audio'];
      }
    }

    return DictionaryEntry(
      word: json['word'],
      phonetic: json['phonetic'],
      audioUrl: audio,
      meanings:
          (json['meanings'] as List).map((m) => Meaning.fromJson(m)).toList(),
    );
  }
}
