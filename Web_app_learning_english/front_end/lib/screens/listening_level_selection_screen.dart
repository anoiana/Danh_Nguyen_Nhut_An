// lib/screens/listening_level_selection_screen.dart
import 'package:flutter/material.dart';

class ListeningLevelSelectionScreen extends StatefulWidget {
  final Function(int level, String topic) onSettingsSelected;

  const ListeningLevelSelectionScreen({Key? key, required this.onSettingsSelected})
      : super(key: key);

  @override
  _ListeningLevelSelectionScreenState createState() =>
      _ListeningLevelSelectionScreenState();
}

class _ListeningLevelSelectionScreenState
    extends State<ListeningLevelSelectionScreen> {
  int? _selectedLevel;
  String? _selectedTopic;

  // <<< START: CẬP NHẬT TOPIC SANG TIẾNG ANH >>>
  // Key là tiếng Anh (sẽ được gửi đến API), Value là cặp [Tên hiển thị (Tiếng Việt), Icon]
  final Map<String, (String, IconData)> _topics = {
    'Education': ('Giáo dục', Icons.school_outlined),
    'Environment': ('Môi trường', Icons.eco_outlined),
    'Society': ('Xã hội', Icons.people_alt_outlined),
    'Technology': ('Công nghệ', Icons.computer_outlined),
    'Health': ('Sức khỏe', Icons.health_and_safety_outlined),
    'Culture': ('Văn hóa', Icons.museum_outlined),
    'Economy & Business': ('Kinh tế & Kinh doanh', Icons.work_outline),
    'Travel & Transport': ('Du lịch & Giao thông', Icons.flight_takeoff_outlined),
    'Work & Career': ('Công việc', Icons.business_center_outlined),
    'Daily Life': ('Cuộc sống hàng ngày', Icons.home_outlined),
    'Entertainment': ('Giải trí', Icons.celebration_outlined),
  };
  // <<< END: CẬP NHẬT TOPIC SANG TIẾNG ANH >>>

  static const Color primaryPink = Color(0xFFE91E63);

  void _submit() {
    if (_selectedLevel != null && _selectedTopic != null) {
      Navigator.pop(context);
      // Gửi đi key tiếng Anh
      widget.onSettingsSelected(_selectedLevel!, _selectedTopic!);
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: primaryPink, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  // <<< CẬP NHẬT HÀM NÀY ĐỂ XỬ LÝ CẤU TRÚC DỮ LIỆU MỚI >>>
  Widget _buildTopicCard(String topicKey, String displayName, IconData icon) {
    final bool isSelected = _selectedTopic == topicKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTopic = topicKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? primaryPink.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryPink : Colors.grey.shade300,
            width: 2.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryPink.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? primaryPink : const Color(0xFFE91E63),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                displayName, // Hiển thị tên tiếng Việt
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryPink : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButton() {
    final bool isReady = _selectedLevel != null && _selectedTopic != null;
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isWideScreen ? 48.0 : 20.0,
        12.0,
        isWideScreen ? 48.0 : 20.0,
        MediaQuery.of(context).padding.bottom + 12.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isReady ? _submit : null,
          icon: const Icon(Icons.play_circle_fill_outlined),
          label: const Text('Bắt Đầu'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: isReady ? 4 : 0,
          ).copyWith(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) return Colors.grey.shade400;
                return primaryPink;
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Tùy Chỉnh Bài Nghe', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        backgroundColor: primaryPink,
        elevation: 1,
        centerTitle: true,
      ),
      bottomNavigationBar: _buildFooterButton(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isWideScreen ? 48.0 : 20.0,
            24.0,
            isWideScreen ? 48.0 : 20.0,
            32.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. Chọn độ khó', Icons.speed_outlined), // Sửa tiêu đề cho gọn
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedLevel,
                      hint: const Text('Chọn một mức độ', style: TextStyle(color: Colors.grey)),
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: primaryPink),
                      // <<< START: CẬP NHẬT CÁC LỰA CHỌN Ở ĐÂY >>>
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Dễ (Beginner)')),
                        DropdownMenuItem(value: 2, child: Text('Trung bình (Intermediate)')),
                        DropdownMenuItem(value: 3, child: Text('Khó (Advanced)')),
                      ],
                      // <<< END: CẬP NHẬT CÁC LỰA CHỌN Ở ĐÂY >>>
                      onChanged: (value) {
                        setState(() {
                          _selectedLevel = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('2. Chọn một chủ đề', Icons.topic_outlined),
              GridView.count(
                crossAxisCount: isWideScreen ? 4 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // <<< CẬP NHẬT CÁCH LẶP QUA MAP >>>
                children: _topics.entries.map((entry) {
                  return _buildTopicCard(entry.key, entry.value.$1, entry.value.$2);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}