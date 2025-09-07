import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../api/auth_service.dart';
import '../api/tts_service.dart';

class FlashcardSettings {
  bool loopMode;
  int displayDuration;
  bool startWithMeaningSide;
  bool autoSpeak;

  FlashcardSettings({
    this.loopMode = false,
    this.displayDuration = 3,
    this.startWithMeaningSide = false,
    this.autoSpeak = true,
  });
}

class FlashcardScreen extends StatefulWidget {
  final GameSession session;
  const FlashcardScreen({Key? key, required this.session}) : super(key: key);

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  FlashcardSettings _settings = FlashcardSettings();
  Timer? _timer;
  bool _isPlaying = false;
  final TextToSpeechService _ttsService = TextToSpeechService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Vocabulary get currentVocab => widget.session.vocabularies[_currentIndex];
  bool _isGoingForward = true;


  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _isFlipped = _settings.startWithMeaningSide;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_settings.autoSpeak && mounted) {
        _speakCurrentWord();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ttsService.stop();
    _audioPlayer.dispose();
    super.dispose();
  }


  void _speakCurrentWord() {
    // if (currentVocab.audioUrl != null && currentVocab.audioUrl!.isNotEmpty) {
    //   _audioPlayer.play(UrlSource(currentVocab.audioUrl!));
    // } else {
    //   _ttsService.setSpeechRate(1.0);
    //   _ttsService.speak(currentVocab.word);
    // }
    _ttsService.setSpeechRate(1.0);
    _ttsService.speak(currentVocab.word);
  }

  void _flipCard() => setState(() => _isFlipped = !_isFlipped);
  void _resetCardState() => setState(() => _isFlipped = _settings.startWithMeaningSide);

  void _nextCard({bool fromAutoPlay = false}) {
    if (!fromAutoPlay) _stopAutoPlay();
    if (_currentIndex >= widget.session.vocabularies.length - 1 && !_settings.loopMode) {
      if (fromAutoPlay) _stopAutoPlay();
      return;
    }
    // CHỈNH SỬA: Cập nhật hướng và index trong cùng một setState để đảm bảo đồng bộ
    setState(() {
      _isGoingForward = true;
      _currentIndex = (_currentIndex + 1) % widget.session.vocabularies.length;
      _isFlipped = _settings.startWithMeaningSide;
    });

    if (_settings.autoSpeak) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _speakCurrentWord();
      });
    }
  }

  void _previousCard() {
    _stopAutoPlay();
    if (_currentIndex > 0) {
      // CHỈNH SỬA: Cập nhật hướng và index trong cùng một setState
      setState(() {
        _isGoingForward = false;
        _currentIndex--;
        _isFlipped = _settings.startWithMeaningSide;
      });
      if (_settings.autoSpeak) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _speakCurrentWord();
        });
      }
    }
  }

  void _toggleAutoPlay() {
    if (_isPlaying) _stopAutoPlay(); else _startAutoPlay();
  }

  void _startAutoPlay() {
    setState(() => _isPlaying = true);
    if (_settings.autoSpeak) _speakCurrentWord();
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: _settings.displayDuration), (timer) {
      _nextCard(fromAutoPlay: true);
    });
  }

  void _stopAutoPlay() {
    _timer?.cancel();
    if (mounted) setState(() => _isPlaying = false);
  }

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color accentPink = Color(0xFFFF80AB);
  static const Color backgroundPink = Color(0xFFFCE4EC);
  static const Color darkTextColor = Color(0xFF333333);

  static const _kCardBorderRadius = BorderRadius.all(Radius.circular(28.0));
  static const _kInnerBorderRadius = BorderRadius.all(Radius.circular(20.0));
  static const _kBottomSheetBorderRadius = BorderRadius.vertical(top: Radius.circular(24.0));


  T _getResponsiveValue<T>(BuildContext context, T small, T medium, T large) {
    final double width = MediaQuery.of(context).size.width;
    if (width > 800) return large;
    if (width > 500) return medium;
    return small;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.vocabularies.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('Flashcard')), body: const Center(child: Text('Không có từ vựng để hiển thị.')));
    }
    final progress = (_currentIndex + 1) / widget.session.vocabularies.length;

    return Scaffold(
      backgroundColor: backgroundPink,
      appBar: AppBar(
        title: const Text('Flashcard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: accentPink.withOpacity(0.5),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: _showSettingsModal, tooltip: 'Cài đặt'),
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 30),
            onPressed: _toggleAutoPlay,
            tooltip: _isPlaying ? 'Tạm dừng' : 'Tự động chạy',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveValue(context, 16.0, 24.0, 32.0),
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      Chip(
                        label: Text(
                          'Từ ${_currentIndex + 1} / ${widget.session.vocabularies.length}',
                          style: const TextStyle(color: primaryPink, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: primaryPink.withOpacity(0.3)),
                      ),
                      const SizedBox(height: 12),
                      // CHỈNH SỬA: Bọc thẻ trong AnimatedSwitcher để có hiệu ứng chuyển động
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          // Key này rất quan trọng, nó báo cho AnimatedSwitcher biết khi nào widget con đã thay đổi
                          // và cần thực hiện hiệu ứng chuyển tiếp.
                          child: _buildAnimatedCard(currentVocab, key: ValueKey<int>(_currentIndex)),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            // Tạo hiệu ứng trượt (slide) dựa trên hướng chuyển thẻ
                            final inOffset = _isGoingForward ? const Offset(1.2, 0.0) : const Offset(-1.2, 0.0);
                            final outOffset = _isGoingForward ? const Offset(-1.2, 0.0) : const Offset(1.2, 0.0);

                            // Phân biệt thẻ mới (đang đi vào) và thẻ cũ (đang đi ra)
                            // bằng cách so sánh key của child với key của thẻ hiện tại.
                            if (child.key == ValueKey<int>(_currentIndex)) {
                              // Thẻ mới đi vào
                              return ClipRect( // Dùng ClipRect để nội dung không bị tràn ra ngoài khi trượt
                                child: SlideTransition(
                                  position: Tween<Offset>(begin: inOffset, end: Offset.zero).animate(animation),
                                  child: FadeTransition(opacity: animation, child: child),
                                ),
                              );
                            } else {
                              // Thẻ cũ đi ra
                              return ClipRect(
                                child: SlideTransition(
                                  position: Tween<Offset>(begin: Offset.zero, end: outOffset).animate(animation),
                                  child: FadeTransition(opacity: Tween<double>(begin: 1.0, end: 0.0).animate(animation), child: child),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildNavigationControls(context),
                      SizedBox(height: _getResponsiveValue(context, 16.0, 20.0, 24.0)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavigationControls(BuildContext context) {
    final bool canGoBack = _currentIndex > 0;
    final bool isLastCard = _currentIndex >= widget.session.vocabularies.length - 1;
    final bool canGoForward = !isLastCard || _settings.loopMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildNavButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: canGoBack ? _previousCard : null,
          tooltip: 'Thẻ trước',
        ),
        // Nút phát âm chính
        ElevatedButton(
          onPressed: _speakCurrentWord,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(22),
            backgroundColor: primaryPink,
            foregroundColor: Colors.white,
            elevation: 8.0,
            shadowColor: primaryPink.withOpacity(0.5),
          ),
          child: const Icon(Icons.volume_up_rounded, size: 36),
        ),
        _buildNavButton(
          icon: Icons.arrow_forward_ios_rounded,
          onPressed: canGoForward ? () => _nextCard(fromAutoPlay: false) : null,
          tooltip: 'Thẻ tiếp theo',
        ),
      ],
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback? onPressed, required String tooltip}) {
    return CircleAvatar(
      radius: 32,
      backgroundColor: Colors.white,
      child: IconButton(
        iconSize: 28,
        icon: Icon(icon),
        color: onPressed != null ? accentPink : Colors.grey.shade300,
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  // CHỈNH SỬA: Thêm tham số Key (không bắt buộc)
  Widget _buildAnimatedCard(Vocabulary vocab, {Key? key}) {
    return GestureDetector(
      key: key, // Gán key cho widget gốc
      onTap: _flipCard,
      onHorizontalDragEnd: (details) {
        // CHỈNH SỬA: Sửa đổi để gọi các hàm đã cập nhật
        if (details.primaryVelocity! < -100) {
          final bool isLastCard = _currentIndex >= widget.session.vocabularies.length - 1;
          if (!isLastCard || _settings.loopMode) {
            _nextCard();
          }
        } else if (details.primaryVelocity! > 100) {
          if (_currentIndex > 0) {
            _previousCard();
          }
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotate = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate, child: child,
            builder: (BuildContext context, Widget? child) {
              final isUnder = (ValueKey(_isFlipped) != child?.key);
              var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
              tilt = isUnder ? -tilt : tilt;
              final value = isUnder ? min(rotate.value, pi / 2) : rotate.value;
              return Transform(
                transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: _buildCardFace(vocab),
      ),
    );
  }

  Widget _buildCardFace(Vocabulary vocab) {
    return Card(
      key: ValueKey<bool>(_isFlipped),
      elevation: 10,
      shadowColor: primaryPink.withOpacity(0.2),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: _kCardBorderRadius),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft, end: Alignment.topRight,
            colors: [Colors.white, _isFlipped ? backgroundPink.withOpacity(0.7) : accentPink.withOpacity(0.1)],
            stops: const [0.6, 1.0],
          ),
        ),
        child: _isFlipped ? _buildBackFace(vocab) : _buildFrontFace(vocab, MediaQuery.of(context).orientation),
      ),
    );
  }

  // Thay thế toàn bộ phương thức _buildFrontFace của bạn bằng phương thức này.

  // Thay thế toàn bộ phương thức _buildFrontFace của bạn bằng phương thức này.

  // Thay thế toàn bộ phương thức _buildFrontFace của bạn bằng phương thức này.

  Widget _buildFrontFace(Vocabulary vocab, Orientation orientation) {
    final hasImage = vocab.userImageBase64 != null && vocab.userImageBase64!.isNotEmpty;

    // Phần nội dung văn bản (không thay đổi)
    final textContent = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              vocab.word,
              style: TextStyle(
                fontSize: _getResponsiveValue(context, 48.0, 58.0, 64.0),
                fontWeight: FontWeight.bold,
                color: primaryPink,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (vocab.phoneticText != null && vocab.phoneticText!.isNotEmpty)
          Text(
            vocab.phoneticText!,
            style: TextStyle(fontSize: _getResponsiveValue(context, 18.0, 22.0, 24.0), color: accentPink),
            textAlign: TextAlign.center,
          ),
      ],
    );

    // CHỈNH SỬA: Sử dụng Stack để chồng lớp và ClipRRect để bo góc ảnh
    final imageContent = Container(
      margin: EdgeInsets.all(_getResponsiveValue(context, 12.0, 16.0, 20.0)),
      // ClipRRect bên ngoài này bo góc cho toàn bộ khung chứa, bao gồm cả nền
      child: ClipRRect(
        borderRadius: _kInnerBorderRadius,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          // Sử dụng Stack để có thể đặt ảnh lên trên một lớp nền màu
          child: Stack(
            fit: StackFit.expand, // Đảm bảo các con của Stack lấp đầy không gian
            children: [
              // Lớp 1: Nền màu cho các khoảng trống (letterbox)

              // Lớp 2: Hình ảnh được bo góc
              if (hasImage)
                Builder(
                  builder: (context) {
                    try {
                      final decodedBytes = base64Decode(base64.normalize(vocab.userImageBase64!));
                      // Đặt ảnh vào trong Center để nó tự động căn giữa
                      return Center(
                        // ClipRRect này sẽ chỉ bo góc cho widget con của nó là Image
                        child: ClipRRect(
                          borderRadius: _kInnerBorderRadius,
                          child: Image.memory(
                            decodedBytes,
                            // BoxFit.contain để đảm bảo hiển thị toàn bộ ảnh
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                        ),
                      );
                    } catch (e) {
                      print('Base64 decode error: $e');
                      // Trả về một Container trống nếu có lỗi để lớp nền vẫn hiển thị
                      return Container();
                    }
                  },
                )
              else
              // Hiển thị placeholder nếu không có ảnh
                _buildImagePlaceholder(),
            ],
          ),
        ),
      ),
    );

    // Phần bố cục cuối cùng (không thay đổi)
    return orientation == Orientation.landscape
        ? Row(children: [Expanded(flex: 5, child: imageContent), Expanded(flex: 5, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: textContent))])
        : Column(children: [Flexible(flex: 5, child: imageContent), Flexible(flex: 3, child: textContent), const SizedBox(height: 20)]);
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(color: backgroundPink, borderRadius: _kInnerBorderRadius),
      child: DottedBorder(
        color: accentPink.withOpacity(0.5), strokeWidth: 2, dashPattern: const [8, 6],
        borderType: BorderType.RRect, radius: const Radius.circular(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_outlined, size: _getResponsiveValue(context, 50.0, 60.0, 70.0), color: accentPink),
              const SizedBox(height: 8),
              Text("Không có ảnh", style: TextStyle(color: accentPink, fontSize: _getResponsiveValue(context, 14.0, 16.0, 18.0))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackFace(Vocabulary vocab) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_getResponsiveValue(context, 20.0, 24.0, 28.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vocab.userDefinedMeaning != null && vocab.userDefinedMeaning!.isNotEmpty) ...[
            _buildSectionHeader('Nghĩa của bạn', Icons.lightbulb_outline_rounded),
            _buildUserMeaningContainer(vocab.userDefinedMeaning!),
            const SizedBox(height: 24),
          ],
          if (vocab.meanings != null && vocab.meanings!.isNotEmpty) ...[
            _buildSectionHeader('Chi tiết từ điển', Icons.menu_book_rounded),
            ...vocab.meanings!.map((meaning) => _buildMeaningWidget(meaning)),
          ],
          if ((vocab.userDefinedMeaning == null || vocab.userDefinedMeaning!.isEmpty) && (vocab.meanings == null || vocab.meanings!.isEmpty))
            const Center(heightFactor: 5, child: Text("Chưa có thông tin chi tiết.", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildUserMeaningContainer(String meaning) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: primaryPink.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPink.withOpacity(0.2)),
      ),
      child: Text(
        '"$meaning"',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: _getResponsiveValue(context, 17.0, 18.0, 19.0),
          color: primaryPink.withOpacity(0.9),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: primaryPink,
      fontSize: _getResponsiveValue(context, 20.0, 22.0, 24.0),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: textStyle.fontSize, color: primaryPink),
          const SizedBox(width: 12),
          Text(title, style: textStyle),
        ],
      ),
    );
  }

  Widget _buildMeaningWidget(Meaning meaning) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: EdgeInsets.all(_getResponsiveValue(context, 16.0, 18.0, 20.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: accentPink.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meaning.partOfSpeech,
            style: TextStyle(
              fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: accentPink,
              fontSize: _getResponsiveValue(context, 16.0, 18.0, 20.0),
            ),
          ),
          const Divider(height: 16, color: backgroundPink),
          ...meaning.definitions.map((def) {
            int index = meaning.definitions.indexOf(def) + 1;
            return Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: _getResponsiveValue(context, 15.0, 16.0, 17.0), height: 1.4, color: darkTextColor),
                      children: [
                        TextSpan(text: '$index. ', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryPink)),
                        TextSpan(text: def.definition),
                      ],
                    ),
                  ),
                  if (def.example != null && def.example!.isNotEmpty)
                    _buildExampleWidget(def.example!),
                ],
              ),
            );
          }).toList(),
          if (meaning.synonyms.isNotEmpty) _buildSubSection("Đồng nghĩa", meaning.synonyms, Colors.green),
          if (meaning.antonyms.isNotEmpty) _buildSubSection("Trái nghĩa", meaning.antonyms, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildExampleWidget(String example) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 12.0, top: 8.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: backgroundPink.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: accentPink.withOpacity(0.5), width: 4.0)),
      ),
      child: Text(
        '"$example"',
        style: TextStyle(fontStyle: FontStyle.italic, color: primaryPink.withOpacity(0.8), fontSize: _getResponsiveValue(context, 14.0, 15.0, 16.0)),
      ),
    );
  }

  Widget _buildSubSection(String title, List<String> items, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: _getResponsiveValue(context, 15.0, 16.0, 17.0))),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0, runSpacing: 4.0,
            children: items.map((item) => Chip(
              label: Text(item, style: TextStyle(fontSize: _getResponsiveValue(context, 13.0, 14.0, 14.0), color: color)),
              backgroundColor: color.withOpacity(0.1),
              side: BorderSide.none,
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _showSettingsModal() {
    _stopAutoPlay();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: _kBottomSheetBorderRadius),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 16),
                  const Text('Cài đặt Flashcard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryPink)),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    title: const Text('Tự động đọc từ'),
                    subtitle: const Text('Phát âm khi chuyển thẻ mới.'),
                    value: _settings.autoSpeak,
                    activeColor: primaryPink,
                    onChanged: (bool value) => setModalState(() => _settings.autoSpeak = value),
                  ),
                  const Divider(),
                  SwitchListTile.adaptive(
                    title: const Text('Chế độ Lặp lại'),
                    value: _settings.loopMode,
                    activeColor: primaryPink,
                    onChanged: (bool value) => setModalState(() => _settings.loopMode = value),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Bắt đầu với mặt nghĩa'),
                    value: _settings.startWithMeaningSide,
                    activeColor: primaryPink,
                    onChanged: (bool value) => setModalState(() => _settings.startWithMeaningSide = value),
                  ),
                  ListTile(
                    title: const Text('Thời gian hiển thị'),
                    trailing: DropdownButton<int>(
                      value: _settings.displayDuration,
                      underline: Container(),
                      items: [2, 3, 4, 5, 7, 10].map((int value) => DropdownMenuItem<int>(value: value, child: Text('$value giây'))).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) setModalState(() => _settings.displayDuration = newValue);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // CHỈNH SỬA: Sửa lại để không reset trạng thái chuyển thẻ một cách không cần thiết
      if(_isFlipped != _settings.startWithMeaningSide) {
        setState(() => _isFlipped = _settings.startWithMeaningSide);
      }
    });
  }
}