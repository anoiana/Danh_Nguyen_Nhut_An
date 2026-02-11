import 'package:flutter/material.dart';

class TranslationBottomSheet extends StatelessWidget {
  final Future<String> Function(String) translateWord;
  final String text;

  const TranslationBottomSheet({
    super.key,
    required this.translateWord,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                  Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: translateWord(text),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(
                  color: Color(0xFFE91E63),
                );
              }
              return Text(
                snapshot.data ?? 'Không thể dịch',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
