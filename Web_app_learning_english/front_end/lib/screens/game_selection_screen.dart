import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/screens/quiz_screen.dart';
import 'package:untitled/screens/quiz_type_selection_screen.dart';
import 'package:untitled/screens/reading_game_screen.dart';
import 'package:untitled/screens/reading_level_selection_screen.dart';
import 'package:untitled/screens/reverse_quiz_screen.dart';
import 'package:untitled/screens/sentence_game_screen.dart';
import 'package:untitled/screens/writing_game_screen.dart';
import '../api/auth_service.dart';
import '../widgets/page_route.dart';
import 'ListeningTypeSelectionScreen.dart';
import 'flashcard_screen.dart';
import 'listening_game_screen.dart';
import 'listening_level_selection_screen.dart';
import 'listening_vocabulary_game_screen.dart';

class GameSelectionScreen extends StatelessWidget {
  final int folderId;
  final String folderName;
  final int vocabularyCount;

  const GameSelectionScreen({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.vocabularyCount,
  });

  // Định nghĩa màu sắc chủ đạo
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundPink = Color(0xFFFCE4EC);
  static const Color darkTextColor = Color(0xFF333333);

  // --- LOGIC CHO CÁC GAME CƠ BẢN (KHÔNG PHẢI NGHE) ---
  void _startGame(BuildContext context, String gameType) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Không tìm thấy người dùng.')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: primaryPink)),
    );

    try {
      // Đổi 'listening' thành 'listening_vocabulary' để không bị trùng lặp
      final session = await AuthService.startGenericGame(
          userId, folderId, gameType == 'listening_vocabulary' ? 'listening' : gameType);

      if (context.mounted) {
        Navigator.pop(context); // Tắt loading
        if (gameType == 'flashcard') {
          Navigator.push(context, ScaleFadePageRoute(page: FlashcardScreen(session: session)));
        } else if (gameType == 'writing') {
          Navigator.push(context, ScaleFadePageRoute(page: WritingGameScreen(session: session)));
        } else if (gameType == 'sentence') {
          Navigator.push(context, ScaleFadePageRoute(page: SentenceGameScreen(session: session)));
        } else if (gameType == 'listening_vocabulary') {
          Navigator.push(context, ScaleFadePageRoute(page: ListeningVocabularyGameScreen(session: session)));
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- LOGIC CHO GAME TRẮC NGHIỆM ANH-VIỆT / VIỆT-ANH ---
  void _navigateToQuizSelection(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return QuizTypeSelectionScreen(
        onSelect: (subType) async {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getInt('userId');
          if (userId == null) return;

          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primaryPink)));

          try {
            if (subType == 'vi_en') {
              final session = await AuthService.startReverseQuizGame(userId, folderId);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReverseQuizScreen(session: session)));
              }
            } else {
              final session = await AuthService.startQuizGame(userId, folderId);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(session: session)));
              }
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
              );
            }
          }
        },
      );
    }));
  }

  // --- LOGIC CHO GAME ĐỌC HIỂU AI ---
  void _navigateToReadingLevelSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingLevelSelectionScreen(
          onSettingsSelected: (level, topic) => _startReadingGame(context, level, topic),
        ),
      ),
    );
  }

  void _startReadingGame(BuildContext context, int level, String topic) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primaryPink)));
    try {
      final content = await AuthService.generateReadingGame(folderId, level, topic);
      final vocabPage = await AuthService.getVocabulariesByFolder(folderId, page: 0, size: 100);
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ReadingGameScreen(
            content: content,
            vocabularyInFolder: vocabPage.content.map((v) => v.word).toList(),
          ),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // <<< START: LOGIC MỚI ĐỂ XỬ LÝ 3 LOẠI GAME NGHE >>>
  void _navigateToListeningSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListeningTypeSelectionScreen(
          onSelect: (gameSubType) {
            Navigator.pop(context); // Đóng màn hình chọn loại
            // Nếu là game cũ 'Nghe & Viết từ'
            if (gameSubType == 'vocabulary') {
              // Kiểm tra điều kiện riêng cho game này
              if(vocabularyCount < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cần ít nhất 1 từ vựng để chơi Nghe & Viết từ.'), backgroundColor: Colors.orangeAccent),
                );
                return;
              }
              // Đổi tên gameType để không bị trùng lặp với gameType 'listening' của backend
              _startGame(context, 'listening_vocabulary');
            }
            // Nếu là các game AI mới
            else {
              // Kiểm tra điều kiện riêng cho game AI
              if(vocabularyCount < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cần ít nhất 5 từ vựng để tạo bài nghe AI.'), backgroundColor: Colors.orangeAccent),
                );
                return;
              }
              _navigateToListeningLevelSelection(context, gameSubType);
            }
          },
        ),
      ),
    );
  }

  void _navigateToListeningLevelSelection(BuildContext context, String gameSubType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListeningLevelSelectionScreen(
          onSettingsSelected: (level, topic) {
            _startAIListeningGame(context, level, topic, gameSubType);
          },
        ),
      ),
    );
  }

  void _startAIListeningGame(BuildContext context, int level, String topic, String gameSubType) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primaryPink)));
    try {
      final content = await AuthService.generateListeningGame(folderId, level, topic, gameSubType);
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListeningGameScreen(content: content, level: level, gameSubType: gameSubType),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // <<< END: LOGIC MỚI CHO LUỒNG GAME NGHE AI >>>

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;
    final crossAxisCount = isLargeScreen ? 3 : 2;

    return Scaffold(
      backgroundColor: backgroundPink,
      appBar: AppBar(
        title: const Text('Chọn Luyện Tập', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 24.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thư mục: $folderName', style: TextStyle(fontSize: isLargeScreen ? 22 : 18, fontWeight: FontWeight.bold, color: primaryPink)),
              const SizedBox(height: 4),
              Text('Bạn đã sẵn sàng luyện tập từ vựng chưa? Hãy chọn một trò chơi bên dưới!', style: TextStyle(fontSize: isLargeScreen ? 16 : 14, color: darkTextColor)),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: isLargeScreen ? 20.0 : 16.0,
                crossAxisSpacing: isLargeScreen ? 20.0 : 16.0,
                childAspectRatio: 1.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGameCard(context, title: 'Flashcard', icon: Icons.style_outlined, onTap: () => _startGame(context, 'flashcard')),
                  _buildGameCard(context, title: 'Trắc nghiệm', icon: Icons.quiz_outlined, isEnabled: vocabularyCount >= 4, onTap: () => _navigateToQuizSelection(context)),
                  _buildGameCard(context, title: 'Viết từ', icon: Icons.edit_outlined, onTap: () => _startGame(context, 'writing')),
                  _buildGameCard(context, title: 'Đặt câu', icon: Icons.segment_outlined, onTap: () => _startGame(context, 'sentence')),
                  _buildGameCard(
                    context,
                    title: 'Luyện Nghe',
                    icon: Icons.headset_mic_outlined,
                    isEnabled: vocabularyCount >= 1,
                    onTap: () => _navigateToListeningSelection(context),
                  ),
                  _buildGameCard(
                    context,
                    title: 'Đọc hiểu',
                    icon: Icons.article_outlined,
                    isEnabled: vocabularyCount >= 1,
                    onTap: () => _navigateToReadingLevelSelection(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
        bool isEnabled = true,
      }) {
    String disabledMessage = 'Yêu cầu không đủ từ vựng.';
    if (title == 'Trắc nghiệm') disabledMessage = 'Cần ít nhất 4 từ vựng.';
    if (title == 'Luyện Nghe') disabledMessage = 'Cần ít nhất 1 từ vựng.';
    if (title == 'Đọc hiểu') disabledMessage = 'Cần ít nhất 1 từ vựng.';

    return Card(
      elevation: isEnabled ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      color: isEnabled ? Colors.white : Colors.grey.shade200,
      child: InkWell(
        onTap: isEnabled ? onTap : () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(disabledMessage), backgroundColor: Colors.orangeAccent),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isEnabled ? icon : Icons.lock_outline, size: 50, color: isEnabled ? primaryPink : Colors.grey.shade400),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isEnabled ? darkTextColor : Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}