import 'package:flutter/material.dart';

class MatchingTile {
  final String id;
  final int vocabId;
  final String content;
  final bool isWord;
  bool isMatched;
  bool isSelected;
  bool isError;

  MatchingTile({
    required this.id,
    required this.vocabId,
    required this.content,
    required this.isWord,
    this.isMatched = false,
    this.isSelected = false,
    this.isError = false,
  });
}
