import 'package:flutter/material.dart';
import '../../view_model/listening_view_model.dart';

class ListeningMcqCard extends StatelessWidget {
  final ListeningViewModel viewModel;
  final int index;
  final dynamic question;
  final Color primaryPink;

  const ListeningMcqCard({
    super.key,
    required this.viewModel,
    required this.index,
    required this.question,
    this.primaryPink = const Color(0xFFE91E63),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryPink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryPink,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    question.question,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...question.options.map((option) {
              bool isSelected = viewModel.selectedMcqOptions[index] == option;
              bool isCorrect = option == question.answer;

              Color borderColor = Colors.grey.shade300;
              Color bgColor = Colors.transparent;
              Color iconColor = Colors.grey;
              IconData icon = Icons.circle_outlined;

              if (viewModel.isSubmitted) {
                if (isCorrect) {
                  borderColor = Colors.green;
                  bgColor = Colors.green.shade50;
                  iconColor = Colors.green;
                  icon = Icons.check_circle;
                } else if (isSelected) {
                  borderColor = Colors.red;
                  bgColor = Colors.red.shade50;
                  iconColor = Colors.red;
                  icon = Icons.cancel;
                }
              } else {
                if (isSelected) {
                  borderColor = primaryPink;
                  bgColor = Colors.pink.shade50;
                  iconColor = primaryPink;
                  icon = Icons.radio_button_checked;
                }
              }

              return GestureDetector(
                onTap:
                    viewModel.isSubmitted
                        ? null
                        : () => viewModel.onMcqOptionSelected(index, option),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
