import 'package:flutter/painting.dart';
import 'package:hellen_app/features/Dictionary/model/dictionary_entry.dart';

class Vocabulary {
  final int id;
  final String word;
  final String? phoneticText;
  final String? audioUrl;
  final String? userDefinedMeaning;
  final String? userDefinedPartOfSpeech;
  final String? userImageBase64;
  final List<Meaning>? meanings;
  final Alignment? imageAlignment;

  Vocabulary({
    required this.id,
    required this.word,
    this.phoneticText,
    this.audioUrl,
    this.userDefinedMeaning,
    this.userDefinedPartOfSpeech,
    this.userImageBase64,
    this.meanings,
    this.imageAlignment,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    var meaningsList = json['meanings'] as List?;
    List<Meaning>? meanings =
        meaningsList?.map((m) => Meaning.fromJson(m)).toList();

    final double? alignX = (json['image_alignment_x'] as num?)?.toDouble();
    final double? alignY = (json['image_alignment_y'] as num?)?.toDouble();
    final Alignment? alignment =
        (alignX != null && alignY != null) ? Alignment(alignX, alignY) : null;

    return Vocabulary(
      id: json['id'],
      word: json['word'],
      phoneticText: json['phoneticText'],
      audioUrl: json['audioUrl'],
      userDefinedMeaning: json['userDefinedMeaning'],
      userDefinedPartOfSpeech: json['userDefinedPartOfSpeech'],
      userImageBase64: json['userImageBase64'],
      meanings: meanings,
      imageAlignment: alignment,
    );
  }
}

class VocabularyPage {
  final List<Vocabulary> content;
  final int totalPages;
  final bool isLast;
  final int totalElements;

  VocabularyPage({
    required this.content,
    required this.totalPages,
    required this.isLast,
    this.totalElements = 0,
  });

  factory VocabularyPage.fromJson(Map<String, dynamic> json) {
    var list = json['content'] as List;
    List<Vocabulary> vocabList =
        list.map((i) => Vocabulary.fromJson(i)).toList();
    return VocabularyPage(
      content: vocabList,
      totalPages: json['totalPages'],
      isLast: json['last'],
      totalElements: json['totalElements'] ?? 0,
    );
  }
}

class VocabularySimpleDTO {
  final int id;
  final String word;
  final String? phoneticText;
  final String? userDefinedMeaning;
  final String? userImageBase64;
  final String? audioUrl;

  VocabularySimpleDTO({
    required this.id,
    required this.word,
    this.phoneticText,
    this.userDefinedMeaning,
    this.userImageBase64,
    this.audioUrl,
  });

  factory VocabularySimpleDTO.fromJson(Map<String, dynamic> json) {
    return VocabularySimpleDTO(
      id: json['id'],
      word: json['word'],
      phoneticText: json['phoneticText'],
      userDefinedMeaning: json['userDefinedMeaning'],
      userImageBase64: json['userImageBase64'],
      audioUrl: json['audioUrl'],
    );
  }
}
