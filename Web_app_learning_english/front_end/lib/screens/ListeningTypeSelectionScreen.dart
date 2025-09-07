// lib/screens/listening_type_selection_screen.dart

import 'package:flutter/material.dart';

class ListeningTypeSelectionScreen extends StatelessWidget {
  final Function(String gameSubType) onSelect;

  const ListeningTypeSelectionScreen({Key? key, required this.onSelect}) : super(key: key);

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundPink = Color(0xFFFCE4EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink.withOpacity(0.5),
      appBar: AppBar(
        title: const Text('Chọn Dạng Bài Nghe', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWideScreen = constraints.maxWidth > 900; // Tăng breakpoint cho 3 cột

          final optionsWidget = _buildOptions(context, isWideScreen);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200), // Tăng chiều rộng tối đa
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: optionsWidget,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptions(BuildContext context, bool isWideScreen) {
    // Tạo danh sách các thẻ
    final List<Widget> cards = [
      _buildOptionCard(
        context,
        title: 'Trắc nghiệm (AI)',
        subtitle: 'Nghe hội thoại và chọn đáp án.',
        icon: Icons.checklist_rtl_rounded,
        onTap: () => onSelect('mcq'),
      ),
      _buildOptionCard(
        context,
        title: 'Điền từ (AI)',
        subtitle: 'Nghe hội thoại và điền từ.',
        icon: Icons.edit_note_rounded,
        onTap: () => onSelect('fitb'),
      ),
      // <<< THẺ MỚI ĐƯỢC THÊM VÀO >>>
      _buildOptionCard(
        context,
        title: 'Nghe & Viết từ',
        subtitle: 'Nghe từng từ và viết lại.',
        icon: Icons.hearing_rounded,
        onTap: () => onSelect('vocabulary'), // 'vocabulary' là subType mới
      ),
    ];

    if (isWideScreen) {
      // Sử dụng Row với các thẻ Expanded
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cards
            .map((card) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: card)))
            .toList(),
      );
    } else {
      // Sử dụng Column như cũ
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cards[0],
          const SizedBox(height: 24),
          cards[1],
          const SizedBox(height: 24),
          cards[2],
        ],
      );
    }
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
          child: Column(
            children: [
              Icon(icon, size: 60, color: primaryPink),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}