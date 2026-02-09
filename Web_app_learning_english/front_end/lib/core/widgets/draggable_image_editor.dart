import 'dart:convert';
import 'package:flutter/material.dart';

/// A widget that allows the user to drag an image within a container to adjust its alignment.
/// Useful for cropping or focusing on a specific part of an image.
class DraggableImageEditor extends StatefulWidget {
  final String? imageBase64;
  final ValueChanged<Alignment> onAlignmentChanged;

  const DraggableImageEditor({
    super.key,
    required this.imageBase64,
    required this.onAlignmentChanged,
  });

  @override
  State<DraggableImageEditor> createState() => _DraggableImageEditorState();
}

class _DraggableImageEditorState extends State<DraggableImageEditor> {
  // Use ValueNotifier to rebuild only the necessary part of the UI
  final ValueNotifier<Alignment> _alignmentNotifier = ValueNotifier(
    Alignment.center,
  );

  // Temporary variable to store the latest calculated alignment
  Alignment _currentAlignment = Alignment.center;

  // Flag to ensure we only schedule one update per frame/tick
  bool _isUpdateScheduled = false;

  @override
  void dispose() {
    _alignmentNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DraggableImageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset alignment if the image changes
    if (widget.imageBase64 != null &&
        oldWidget.imageBase64 != widget.imageBase64) {
      _currentAlignment = Alignment.center;
      _alignmentNotifier.value = Alignment.center;
    }
  }

  /// Handles the drag gesture to update image alignment
  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.imageBase64 == null) return;

    final size = context.size;
    if (size == null) return;

    final containerWidth = size.width;
    final containerHeight = size.height;

    // Calculate delta normalized to [-1.0, 1.0] range
    // Alignment coordinates: 0 is center, -1 is left/top, 1 is right/bottom
    // We divide by (size/2) because alignment goes from -1 to 1 (range of 2)
    final dx = details.delta.dx / (containerWidth / 2);
    final dy = details.delta.dy / (containerHeight / 2);

    // Update temporary value immediately
    _currentAlignment = Alignment(
      (_currentAlignment.x + dx).clamp(-1.0, 1.0),
      (_currentAlignment.y + dy).clamp(-1.0, 1.0),
    );

    // Throttle updates to avoid excessive rebuilding/callbacks
    if (!_isUpdateScheduled) {
      _isUpdateScheduled = true;
      Future.delayed(Duration.zero, () {
        if (mounted) {
          _alignmentNotifier.value = _currentAlignment;
          widget.onAlignmentChanged(_currentAlignment);
          _isUpdateScheduled = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: GestureDetector(
        onPanUpdate: _handlePanUpdate,
        child: ValueListenableBuilder<Alignment>(
          valueListenable: _alignmentNotifier,
          builder: (context, alignment, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                _buildImageContainer(alignment),
                if (widget.imageBase64 != null) _buildDragIndicator(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageContainer(Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF8BBD0), width: 2),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFFCE4EC),
      ),
      child:
          widget.imageBase64 != null
              ? _buildImage(alignment)
              : const Center(
                child: Icon(
                  Icons.photo_size_select_actual_outlined,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
    );
  }

  Widget _buildImage(Alignment alignment) {
    try {
      String cleanBase64 = widget.imageBase64!;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      final bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));

      return ClipRRect(
        borderRadius: BorderRadius.circular(6), // Slightly less than container
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          alignment: alignment,
          errorBuilder:
              (context, error, stackTrace) =>
                  _buildErrorIcon(Icons.broken_image),
        ),
      );
    } catch (e) {
      return _buildErrorIcon(Icons.error_outline, color: Colors.red);
    }
  }

  Widget _buildErrorIcon(IconData icon, {Color color = Colors.grey}) {
    return Center(child: Icon(icon, size: 40, color: color));
  }

  Widget _buildDragIndicator() {
    return IgnorePointer(
      child: Icon(
        Icons.open_with_rounded,
        color: Colors.white.withOpacity(0.7),
        size: 40,
        shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
      ),
    );
  }
}
