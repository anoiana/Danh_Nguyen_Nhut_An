import 'package:flutter/material.dart';

class QuizTypeSelectionScreen extends StatelessWidget {
  final Function(String subType) onSelect;

  const QuizTypeSelectionScreen({super.key, required this.onSelect});

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color accentPink = Color(0xFFFF80AB);
  static const Color backgroundPink = Color(0xFFFCE4EC);
  static const Color darkTextColor = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,
      appBar: AppBar(
        title: const Text('Chọn Chế Độ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bạn muốn luyện tập theo cách nào?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              const SizedBox(height: 32),
              _buildOptionCard(
                context,
                title: 'Word ➔ Meanings',
                subtitle: 'Chọn nghĩa đúng cho từ tiếng Anh.',
                icon: Icons.spellcheck,
                startColor: primaryPink,
                endColor: accentPink,
                onTap: () {
                  onSelect('en_vi');
                },
              ),
              const SizedBox(height: 24),
              _buildOptionCard(
                context,
                title: 'Meaning ➔ Words',
                subtitle: 'Chọn từ tiếng Anh đúng cho nghĩa.',
                icon: Icons.translate,
                startColor: primaryPink,
                endColor: accentPink,
                onTap: () {
                  onSelect('vi_en');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color startColor,
        required Color endColor,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 8,
      shadowColor: startColor.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias, // Cần thiết để gradient không bị tràn
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Icon mờ trang trí ở góc
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 120,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              // Nội dung chính
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 2.0, color: Colors.black26, offset: Offset(1,1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}