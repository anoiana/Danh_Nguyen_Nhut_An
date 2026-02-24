// lib/features/Study_Modes/view/listening_level_selection_view.dart
import 'package:flutter/material.dart';

class ListeningLevelSelectionView extends StatefulWidget {
  final Function(int level, String topic) onSettingsSelected;

  const ListeningLevelSelectionView({
    Key? key,
    required this.onSettingsSelected,
  }) : super(key: key);

  @override
  _ListeningLevelSelectionViewState createState() =>
      _ListeningLevelSelectionViewState();
}

class _ListeningLevelSelectionViewState
    extends State<ListeningLevelSelectionView> {
  int? _selectedLevel;
  String? _selectedTopic;

  final Map<String, (String, IconData)> _topics = {
    'Education': ('Giáo dục', Icons.school_rounded),
    'Environment': ('Môi trường', Icons.eco_rounded),
    'Society': ('Xã hội', Icons.people_alt_rounded),
    'Technology': ('Công nghệ', Icons.computer_rounded),
    'Health': ('Sức khỏe', Icons.health_and_safety_rounded),
    'Culture': ('Văn hóa', Icons.museum_rounded),
    'Economy & Business': ('Kinh tế', Icons.work_rounded),
    'Travel & Transport': ('Du lịch', Icons.flight_takeoff_rounded),
    'Work & Career': ('Công việc', Icons.business_center_rounded),
    'Daily Life': ('Đời sống', Icons.home_rounded),
    'Entertainment': ('Giải trí', Icons.celebration_rounded),
  };

  static const Color primaryPink = Color(0xFFE91E63);

  void _submit() {
    if (_selectedLevel != null && _selectedTopic != null) {
      Navigator.pop(context);
      widget.onSettingsSelected(_selectedLevel!, _selectedTopic!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF121212), const Color(0xFF2C2C2C)]
                    : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isWideScreen ? 48.0 : 24.0,
                    16.0,
                    isWideScreen ? 48.0 : 24.0,
                    100.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Độ khó', Icons.bar_chart_rounded),
                      const SizedBox(height: 16),
                      _buildLevelSelector(),

                      const SizedBox(height: 32),
                      _buildSectionHeader('Chủ đề', Icons.category_rounded),
                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: isWideScreen ? 4 : 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children:
                            _topics.entries.map((entry) {
                              return _buildTopicCard(
                                entry.key,
                                entry.value.$1,
                                entry.value.$2,
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: _buildFooterButton(),
    );
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: primaryPink),
            ),
          ),
          const Expanded(
            child: Text(
              'Tùy Chỉnh Bài Nghe',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 48), // Spacer to balance back button
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryPink, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _selectedLevel,
          hint: Text('Chọn mức độ', style: TextStyle(color: Colors.grey[400])),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryPink,
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text('🟢 Dễ (Beginner)')),
            DropdownMenuItem(
              value: 2,
              child: Text('🟡 Trung bình (Intermediate)'),
            ),
            DropdownMenuItem(value: 3, child: Text('🔴 Khó (Advanced)')),
          ],
          onChanged: (value) => setState(() => _selectedLevel = value),
        ),
      ),
    );
  }

  Widget _buildTopicCard(String topicKey, String displayName, IconData icon) {
    final bool isSelected = _selectedTopic == topicKey;

    return GestureDetector(
      onTap: () => setState(() => _selectedTopic = topicKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? primaryPink : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
                      ? primaryPink.withOpacity(0.4)
                      : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Theme.of(context).brightness == Brightness.dark
                        ? primaryPink.withOpacity(0.1)
                        : Colors.pink.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : primaryPink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButton() {
    final bool isReady = _selectedLevel != null && _selectedTopic != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isReady ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPink,
              foregroundColor: Colors.white,
              elevation: isReady ? 8 : 0,
              shadowColor: primaryPink.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : Colors.grey[300],
              disabledForegroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[500]
                      : Colors.grey[500],
            ),
            child: const Text(
              'Bắt Đầu Nghe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
