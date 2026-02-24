import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_model/matching_view_model.dart';
import '../model/matching_tile.dart';
import '../../../core/widgets/custom_loading_widget.dart';
import '../../../core/widgets/game_finish_dialog.dart';

class MatchingView extends StatefulWidget {
  final int folderId;
  final String folderName;

  const MatchingView({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<MatchingView> {
  final MatchingViewModel _viewModel = MatchingViewModel();

  // Colors
  static const Color primaryPink = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      await _viewModel.init(userId, widget.folderId);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showCompletionDialog() {
    showGameFinishDialog(
      context: context,
      correctCount: _viewModel.matchedPairs,
      wrongCount: _viewModel.wrongVocabularies.length,
      extraStats: {
        'Thời gian': _viewModel.timeString,
        'Số bước': '${_viewModel.moves}',
      },
      onClose: () {
        Navigator.of(context).pop(); // close dialog
        Navigator.of(context).pop(); // back to selection
      },
      onReplay: () {
        Navigator.of(context).pop(); // close dialog
        _loadData();
      },
      wrongWordsCount: _viewModel.wrongVocabularies.length,
      onRetryWrongWords:
          _viewModel.wrongVocabularies.isNotEmpty
              ? () {
                Navigator.of(context).pop(); // close dialog
                _viewModel.startWrongWordsRetry();
              }
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
        child: Stack(
          children: [
            // Background decorations
            Positioned(
              top: -80,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).primaryColor.withOpacity(0.3)
                          : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).primaryColor.withOpacity(0.3)
                          : Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: AnimatedBuilder(
                animation: _viewModel,
                builder: (context, child) {
                  if (_viewModel.isBusy) {
                   return CustomLoadingWidget(
                      message: 'Đang tải dữ liệu...',
                      color: Theme.of(context).colorScheme.primary,
                    );
                  }
                  if (_viewModel.errorMessage.isNotEmpty) {
                    return Center(child: Text(_viewModel.errorMessage));
                  }

                  return Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // 3 columns for mobile, 4-5 for tablets
                                int cols = constraints.maxWidth > 600 ? 5 : 3;
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        childAspectRatio: 0.85,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: _viewModel.tiles.length,
                                  itemBuilder: (context, index) {
                                    final tile = _viewModel.tiles[index];
                                    return _buildTile(tile);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          if (!_viewModel.isFinished) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _showCompletionDialog,
            label: const Text('Xem Kết Quả'),
            icon: const Icon(Icons.emoji_events_rounded),
            backgroundColor: primaryPink,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
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
                          : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_rounded,
                      color: primaryPink,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _viewModel.timeString,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: primaryPink,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              // Placeholder to balance layout or Moves counter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Bước: ${_viewModel.moves}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? primaryPink
                            : const Color(0xFF880E4F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress: Paired vs Total
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value:
                  _viewModel.totalPairs > 0
                      ? _viewModel.matchedPairs / _viewModel.totalPairs
                      : 0,
              minHeight: 8,
              backgroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                primaryPink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(MatchingTile tile) {
    if (tile.isMatched) {
      return AnimatedOpacity(
        opacity: 0.0,
        duration: const Duration(milliseconds: 500),
        child: Container(),
      );
    }

    Color cardColor;
    Color textColor;
    double elevation = 4;
    Border? border;

    if (tile.isError) {
      cardColor = const Color(0xFFFFEBEE); // Light Red
      textColor = Colors.red;
      border = Border.all(color: Colors.red, width: 2);
    } else if (tile.isSelected) {
      cardColor = const Color(0xFFFCE4EC); // Light Pink
      textColor = primaryPink;
      border = Border.all(color: primaryPink, width: 2);
      elevation = 8;
    } else {
      // Different colors for Word and Meaning
      if (tile.isWord) {
        cardColor = const Color(0xFFFFF3E0); // Light Orange/Amber for Word
        textColor = const Color(0xFFE65100); // Darker Orange text
      } else {
        cardColor = const Color(0xFFE3F2FD); // Light Blue for Meaning
        textColor = const Color(0xFF1565C0); // Darker Blue text
      }
    }

    return GestureDetector(
      onTap: () => _viewModel.selectTile(tile),
      onDoubleTap: () => _viewModel.deselectTile(tile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: border,
          boxShadow: [
            BoxShadow(
              color: primaryPink.withOpacity(elevation > 4 ? 0.3 : 0.1),
              blurRadius: elevation,
              offset: Offset(0, elevation / 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Optional: Add icon/visual if needed based on content type
              Text(
                tile.content,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: tile.content.length > 12 ? 13 : 15,
                  height: 1.2,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
