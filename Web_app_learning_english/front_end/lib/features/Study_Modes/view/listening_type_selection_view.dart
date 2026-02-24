// lib/features/Study_Modes/view/listening_type_selection_view.dart

import 'package:flutter/material.dart';

class ListeningTypeSelectionView extends StatelessWidget {
  final Function(String gameSubType) onSelect;

  const ListeningTypeSelectionView({Key? key, required this.onSelect})
    : super(key: key);

  static const Color primaryPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : primaryPink),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [
                      const Color(0xFF1E1E1E),
                      Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ]
                    : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background elements
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -40,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Luyện Nghe 🎧',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color:
                            isDark
                                ? Theme.of(context).colorScheme.primary
                                : primaryPink,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chọn chế độ luyện tập phù hợp với bạn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),

                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive layout logic
                          final isWide = constraints.maxWidth > 800;

                          final optionCards = [
                            _buildOptionCard(
                              context,
                              title: 'Trắc nghiệm',
                              subtitle: 'Nghe hội thoại và chọn đáp án đúng.',
                              icon: Icons.checklist_rounded,
                              color: Colors.blueAccent,
                              onTap: () => onSelect('mcq'),
                            ),
                            const SizedBox(height: 20, width: 20),
                            _buildOptionCard(
                              context,
                              title: 'Điền từ',
                              subtitle:
                                  'Nghe và điền từ còn thiếu vào ô trống.',
                              icon: Icons.edit_note_rounded,
                              color: Colors.orangeAccent,
                              onTap: () => onSelect('fitb'),
                            ),
                            const SizedBox(height: 20, width: 20),
                            _buildOptionCard(
                              context,
                              title: 'Chép chính tả',
                              subtitle: 'Nghe từng từ và viết lại chính xác.',
                              icon: Icons.keyboard_alt_rounded,
                              color: Colors.green,
                              onTap: () => onSelect('vocabulary'),
                            ),
                          ];

                          if (isWide) {
                            return Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: optionCards,
                                ),
                              ),
                            );
                          } else {
                            return SingleChildScrollView(
                              child: Column(children: optionCards),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.only(bottom: 24), // For column spacing
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border:
            isDark ? Border.all(color: color.withOpacity(0.3), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.3)
                    : color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? color.withOpacity(0.2)
                            : color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
