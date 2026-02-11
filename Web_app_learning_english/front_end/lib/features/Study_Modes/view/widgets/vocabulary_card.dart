import 'package:flutter/material.dart';
import '../../view_model/listening_view_model.dart';
import '../../../Vocabulary/model/vocabulary.dart';

class VocabularyCard extends StatelessWidget {
  final ListeningViewModel viewModel;
  final Vocabulary currentVocab;
  final Color primaryPink;

  const VocabularyCard({
    super.key,
    required this.viewModel,
    required this.currentVocab,
    this.primaryPink = const Color(0xFFE91E63),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? primaryPink.withOpacity(0.1)
                      : const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryPink.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.headphones_rounded, size: 16, color: primaryPink),
                const SizedBox(width: 8),
                Text(
                  'Nghe và điền từ',
                  style: TextStyle(
                    color: primaryPink.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: viewModel.speakCurrentVocab,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      Theme.of(context).brightness == Brightness.dark
                          ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
                          : [Colors.white, const Color(0xFFFFF0F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryPink.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Theme.of(context).cardColor,
                    blurRadius: 10,
                    offset: const Offset(-5, -5),
                  ),
                ],
              ),
              child: Icon(
                Icons.volume_up_rounded,
                size: 64,
                color: primaryPink,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chạm để nghe lại',
            style: TextStyle(
              color:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.6) ??
                  Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (viewModel.isSubmitted &&
              viewModel.feedbackState == FeedbackState.incorrect) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Nghĩa: ${currentVocab.userDefinedMeaning ?? "Chưa có"}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
