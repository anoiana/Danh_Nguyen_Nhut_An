import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'flashcard_view.dart';
import 'quiz_view.dart';
import 'writing_view.dart';
import 'matching_view.dart';
import 'sentence_view.dart';
import 'reading_view.dart';
import 'listening_view.dart';
import '../view_model/listening_view_model.dart';
import '../view_model/flashcard_view_model.dart';
import 'package:provider/provider.dart';
import 'listening_type_selection_view.dart';
import 'listening_level_selection_view.dart';
import 'reading_level_selection_view.dart';
import 'speaking_view.dart';
import '../view_model/speaking_view_model.dart';

// Theme Colors
const Color primaryPink = Color(0xFFE91E63);
const Color backgroundPink = Color(0xFFFCE4EC);

class StudyModeSelectionView extends StatefulWidget {
  final int folderId;
  final String folderName;
  final int vocabularyCount;

  const StudyModeSelectionView({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.vocabularyCount,
  });

  @override
  State<StudyModeSelectionView> createState() => _StudyModeSelectionViewState();
}

class _StudyModeSelectionViewState extends State<StudyModeSelectionView> {
  void _navigateToListeningSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ListeningTypeSelectionView(
              onSelect: (gameSubType) async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getInt('userId');
                if (userId == null) return;

                if (gameSubType == 'vocabulary') {
                  if (widget.vocabularyCount < 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cần ít nhất 1 từ vựng.'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                    return;
                  }
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ListeningView(
                              folderId: widget.folderId,
                              userId: userId,
                              initialType: ListeningGameType.vocabulary,
                            ),
                      ),
                    );
                  }
                } else {
                  if (widget.vocabularyCount < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cần ít nhất 5 từ vựng.'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                    return;
                  }
                  _navigateToListeningLevelSelection(
                    context,
                    gameSubType,
                    userId,
                  );
                }
              },
            ),
      ),
    );
  }

  void _navigateToListeningLevelSelection(
    BuildContext context,
    String gameSubType,
    int userId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ListeningLevelSelectionView(
              onSettingsSelected: (level, topic) {
                _startAIListeningGame(
                  context,
                  level,
                  topic,
                  gameSubType,
                  userId,
                );
              },
            ),
      ),
    );
  }

  void _startAIListeningGame(
    BuildContext context,
    int level,
    String topic,
    String gameSubType,
    int userId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ListeningView(
              folderId: widget.folderId,
              userId: userId,
              level: level,
              topic: topic,
              subType: gameSubType,
              initialType: ListeningGameType.ai,
            ),
      ),
    );
  }

  void _navigateToReadingLevelSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ReadingLevelSelectionView(
              onSettingsSelected: (level, topic) {
                _startReadingGame(context, level, topic);
              },
            ),
      ),
    );
  }

  void _startReadingGame(BuildContext context, int level, String topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ReadingView(
              folderId: widget.folderId,
              folderName: widget.folderName,
              level: level,
              topic: topic,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryPink,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                widget.folderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Base Gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF80AB),
                          Color(0xFFE91E63),
                          Color(0xFFC2185B),
                        ],
                      ),
                    ),
                  ),
                  // 2. Decorative Circles (Glass/Bubble effect)
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  // 3. Central Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.school_outlined,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.text_fields,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.vocabularyCount} từ vựng',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildModeCard('Thẻ ghi nhớ', 'Ôn tập nhanh', Icons.style, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChangeNotifierProvider(
                            create: (_) => FlashcardViewModel(),
                            child: FlashcardView(
                              folderId: widget.folderId,
                              folderName: widget.folderName,
                            ),
                          ),
                    ),
                  );
                }),
                _buildModeCard(
                  'Trắc nghiệm',
                  'Kiểm tra kiến thức',
                  Icons.quiz,
                  () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder:
                          (context) => Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
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
                                const Text(
                                  'Chọn loại trắc nghiệm',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryPink,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildBottomSheetOption(
                                  context,
                                  'Tiếng Anh -> Tiếng Việt',
                                  Icons.translate,
                                  () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => QuizView(
                                              folderId: widget.folderId,
                                              folderName: widget.folderName,
                                              subType: 'en_vi',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildBottomSheetOption(
                                  context,
                                  'Tiếng Việt -> Tiếng Anh',
                                  Icons.swap_horiz,
                                  () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => QuizView(
                                              folderId: widget.folderId,
                                              folderName: widget.folderName,
                                              subType: 'vi_en',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                    );
                  },
                  enabled: widget.vocabularyCount >= 4,
                ),
                _buildModeCard(
                  'Gõ từ',
                  'Rèn luyện chính tả',
                  Icons.keyboard,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => WritingView(
                              folderId: widget.folderId,
                              folderName: widget.folderName,
                            ),
                      ),
                    );
                  },
                ),
                _buildModeCard(
                  'Ghép thẻ',
                  'Phản xạ từ vựng',
                  Icons.join_inner,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => MatchingView(
                              folderId: widget.folderId,
                              folderName: widget.folderName,
                            ),
                      ),
                    );
                  },
                  enabled: widget.vocabularyCount >= 4,
                ),
                _buildModeCard(
                  'Đặt câu',
                  'Cấu trúc câu',
                  Icons.text_fields,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SentenceView(
                              folderId: widget.folderId,
                              folderName: widget.folderName,
                            ),
                      ),
                    );
                  },
                  enabled: widget.vocabularyCount >= 4,
                ),
                _buildModeCard(
                  'Luyện Nghe',
                  'Luyện nghe chủ động',
                  Icons.headphones,
                  () {
                    _navigateToListeningSelection(context);
                  },
                  enabled: widget.vocabularyCount >= 1,
                ),
                _buildModeCard(
                  'Đọc hiểu',
                  'Đọc hiểu văn bản',
                  Icons.menu_book,
                  () {
                    _navigateToReadingLevelSelection(context);
                  },
                  enabled: widget.vocabularyCount >= 1,
                ),
                _buildModeCard(
                  'Luyện Nói',
                  'Phát âm chuẩn',
                  Icons.record_voice_over_rounded,
                  () async {
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getInt('userId');
                    if (userId == null) return;
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChangeNotifierProvider(
                                create: (_) => SpeakingViewModel(),
                                child: SpeakingView(
                                  folderId: widget.folderId,
                                  folderName: widget.folderName,
                                  userId: userId,
                                ),
                              ),
                        ),
                      );
                    }
                  },
                  enabled: widget.vocabularyCount >= 1,
                ),
              ],
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildBottomSheetOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryPink, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        boxShadow:
            enabled
                ? [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.05),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              enabled
                  ? onTap
                  : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Chưa đủ từ vựng để chơi chế độ này'),
                            ),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color:
                          enabled
                              ? primaryPink.withOpacity(0.08)
                              : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: enabled ? primaryPink : Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: enabled ? Colors.black87 : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled ? Colors.black54 : Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
