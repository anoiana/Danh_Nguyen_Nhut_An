import 'package:flutter/material.dart';
import '../../view_model/listening_view_model.dart';
import 'listening_mcq_card.dart';

class AITaskContent extends StatelessWidget {
  final ListeningViewModel viewModel;
  final Color primaryPink;

  const AITaskContent({
    super.key,
    required this.viewModel,
    this.primaryPink = const Color(0xFFE91E63),
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (viewModel.isSubmitted)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue.withOpacity(0.2)
                      : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Kết quả của bạn',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${viewModel.aiSubType == 'mcq' ? viewModel.mcqScore : viewModel.fitbScore}",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

        if (viewModel.aiSubType == 'mcq')
          ...viewModel.aiContent!.mcq.asMap().entries.map(
            (e) => ListeningMcqCard(
              viewModel: viewModel,
              index: e.key,
              question: e.value,
              primaryPink: primaryPink,
            ),
          ),

        if (viewModel.aiSubType == 'fitb' && viewModel.aiContent?.fitb != null)
          _buildFitbCard(context),

        const SizedBox(height: 32),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed:
                viewModel.isSubmitted
                    ? viewModel.resetAIGame
                    : viewModel.checkAIAnswers,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: primaryPink.withOpacity(0.4),
            ),
            child: Text(
              viewModel.isSubmitted ? "Làm lại bài" : "Nộp bài",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFitbCard(BuildContext context) {
    if (viewModel.aiContent?.fitb == null) {
      return const SizedBox.shrink();
    }

    final textParts = viewModel.aiContent!.fitb!.textWithBlanks.split(
      RegExp(r'____\(\d+\)____'),
    );
    final spans = <InlineSpan>[];
    for (var i = 0; i < textParts.length; i++) {
      // Regular text
      spans.add(
        TextSpan(text: textParts[i], style: const TextStyle(height: 2)),
      );

      // Blank field
      if (i < viewModel.fitbControllers.length) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isCorrect = viewModel.fitbResults[i];
        Color underlineColor =
            isDark ? Colors.grey.shade600 : Colors.grey.shade400;
        if (viewModel.isSubmitted) {
          underlineColor = (isCorrect ?? false) ? Colors.green : Colors.red;
        }

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: viewModel.fitbControllers[i],
                readOnly: viewModel.isSubmitted,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      viewModel.isSubmitted
                          ? (isDark
                              ? (isCorrect ?? false
                                  ? Colors.greenAccent
                                  : Colors.redAccent)
                              : underlineColor)
                          : (isDark ? Colors.white : Colors.black),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: underlineColor, width: 1.5),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryPink, width: 2.5),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: RichText(
          text: TextSpan(
            children: spans,
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  const Color(0xFF333333),
              fontSize: 16,
              height: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}
