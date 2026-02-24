import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../api/tts_service.dart';
import '../../../features/Vocabulary/model/vocabulary.dart';
import '../view_model/flashcard_view_model.dart';
import '../../../core/widgets/custom_loading_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Colors are now derived from Theme.of(context)

class FlashcardView extends StatefulWidget {
  final int folderId;
  final String folderName;

  const FlashcardView({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _lastIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadData();
    _ttsService.init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FlashcardViewModel>().addListener(_onViewModelChanged);
      }
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null && mounted) {
      context.read<FlashcardViewModel>().init(userId, widget.folderId);
    }
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    final viewModel = context.read<FlashcardViewModel>();

    if (viewModel.currentIndex != _lastIndex) {
      _lastIndex = viewModel.currentIndex;

      // Auto speak if enabled
      if (viewModel.settings.autoSpeak && !viewModel.isBusy) {
        // Delay slightly to let animation start
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && viewModel.currentIndex == _lastIndex) {
            _speakCurrentWord(viewModel);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _speakCurrentWord(FlashcardViewModel viewModel) {
    final vocab = viewModel.currentVocabulary;
    if (vocab != null) {
      _ttsService.setSpeechRate(0.5);
      _ttsService.speak(vocab.word);
    }
  }

  void _showSettingsModal(FlashcardViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final settings = viewModel.settings;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cài đặt Flashcard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Lặp lại danh sách'),
                    value: settings.loopMode,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      viewModel.updateSettings(loopMode: val);
                      setStateModal(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Tự động phát âm thanh'),
                    value: settings.autoSpeak,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      viewModel.updateSettings(autoSpeak: val);
                      setStateModal(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Bắt đầu bằng mặt nghĩa'),
                    value: settings.startWithMeaningSide,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      viewModel.updateSettings(startWithMeaningSide: val);
                      setStateModal(() {});
                    },
                  ),
                  ListTile(
                    title: const Text('Thời gian chuyển thẻ tự động'),
                    subtitle: Slider(
                      value: settings.displayDuration.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${settings.displayDuration}s',
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        viewModel.updateSettings(displayDuration: val.toInt());
                        setStateModal(() {});
                      },
                    ),
                    trailing: Text(
                      '${settings.displayDuration}s',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlashcardViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isBusy && viewModel.vocabularies.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: CustomLoadingWidget(
              message: 'Đang tải dữ liệu...',
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }

        if (viewModel.errorMessage.isNotEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Lỗi: ${viewModel.errorMessage}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (viewModel.vocabularies.isEmpty) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.celebration_rounded,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tuyệt vời!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bạn chưa có flashcard nào trong thư mục này.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate progress for segmented bar
        final total = viewModel.vocabularies.length;
        final current = viewModel.currentIndex + 1;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    Theme.of(context).brightness == Brightness.dark
                        ? [
                          const Color(0xFF1E1E1E),
                          Theme.of(context).primaryColor.withOpacity(0.5),
                        ]
                        : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Background Circles
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.3)
                                : Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      // Header
                      _buildHeader(context, viewModel, current, total),

                      const SizedBox(height: 10),

                      // Card Area
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Fake card behind for "stack" effect
                                if (total > 1)
                                  Positioned(
                                    top: 30, // pushed down slightly
                                    child: Transform.scale(
                                      scale: 0.92,
                                      child: Container(
                                        width: constraints.maxWidth * 0.85,
                                        height: constraints.maxHeight * 0.8,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).cardColor.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(
                                            32,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(
                                                context,
                                              ).shadowColor.withOpacity(0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                // Main Card
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    transitionBuilder: (child, animation) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(
                                            0.1,
                                            0,
                                          ), // Subtle slide
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _buildAnimatedCard(
                                      viewModel.currentVocabulary!,
                                      viewModel,
                                      key: ValueKey(viewModel.currentIndex),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Controls Dock
                      _buildControls(viewModel),
                      const SizedBox(height: 30),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    FlashcardViewModel viewModel,
    int current,
    int total,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.1)
                          : Theme.of(context).cardColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.1)
                          : Theme.of(context).cardColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$current / $total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.1)
                          : Theme.of(context).cardColor.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _showSettingsModal(viewModel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segmented Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  Container(
                    height: 6,
                    width: width,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    width: width * (current / total),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControls(FlashcardViewModel viewModel) {
    final bool canGoBack = viewModel.currentIndex > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color:
                canGoBack
                    ? const Color(0xFFFFA000)
                    : Colors.grey[300], // Orange/Grey
            onPressed: canGoBack ? viewModel.previousCard : null,
            splashRadius: 24,
          ),

          // Play/Pause
          GestureDetector(
            onTap: viewModel.toggleAutoPlay,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    viewModel.isPlaying
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (viewModel.isPlaying
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary)
                        .withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                viewModel.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // Next Button
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded),
            color: const Color(0xFF4CAF50), // Green for forward
            onPressed: viewModel.nextCard,
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(
    Vocabulary vocab,
    FlashcardViewModel viewModel, {
    Key? key,
  }) {
    return GestureDetector(
      key: key,
      onTap: viewModel.flipCard,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: pi, end: 0.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutBack),
          );

          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final isUnder = (ValueKey(viewModel.isFlipped) != child?.key);
              final value = isUnder ? min(rotate.value, pi / 2) : rotate.value;

              return Transform(
                transform: Matrix4.rotationY(value),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: _buildCardContent(vocab, viewModel),
      ),
    );
  }

  Widget _buildCardContent(Vocabulary vocab, FlashcardViewModel viewModel) {
    if (viewModel.isFlipped) {
      return _buildBackFace(vocab);
    } else {
      return _buildFrontFace(vocab);
    }
  }

  Widget _buildFrontFace(Vocabulary vocab) {
    return Container(
      key: const ValueKey(false),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: -30,
            right: -30,
            child: Icon(
              Icons.spa,
              size: 200,
              color: Colors.pink.withOpacity(0.03),
            ),
          ),
          Column(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(child: _buildImage(vocab)),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        vocab.word,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              const Color(0xFF2D2D2D),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (vocab.phoneticText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            vocab.phoneticText!,
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap:
                            () => _speakCurrentWord(
                              context.read<FlashcardViewModel>(),
                            ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                          ), 
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chạm để lật',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackFace(Vocabulary vocab) {
    return Container(
      key: const ValueKey(true),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Definition',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.volume_up_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed:
                    () => _speakCurrentWord(context.read<FlashcardViewModel>()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vocab.userDefinedMeaning != null)
                    Text(
                      vocab.userDefinedMeaning!,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            const Color(0xFF333333),
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (vocab.meanings != null)
                    ...vocab.meanings!.map(
                      (m) => Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.partOfSpeech.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...m.definitions.map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        d.definition,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.8),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(Vocabulary vocab) {
    if (vocab.userImageBase64 != null && vocab.userImageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(vocab.userImageBase64!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(bytes, fit: BoxFit.contain),
        );
      } catch (e) {
        return const Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: Colors.white,
        );
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 48,
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ],
    );
  }
}
