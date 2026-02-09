import 'dart:convert';
import 'package:flutter/material.dart';

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
  // Vẫn dùng ValueNotifier để build lại UI một cách hiệu quả
  final ValueNotifier<Alignment> _alignmentNotifier = ValueNotifier(
    Alignment.center,
  );

  // Biến tạm để lưu alignment mới nhất được tính toán
  Alignment _currentAlignment = Alignment.center;

  // Cờ để đảm bảo chúng ta chỉ lên lịch một lần cập nhật mỗi frame
  bool _isUpdateScheduled = false;

  @override
  void dispose() {
    _alignmentNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DraggableImageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageBase64 != null &&
        oldWidget.imageBase64 != widget.imageBase64) {
      _currentAlignment = Alignment.center;
      _alignmentNotifier.value = Alignment.center;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // Chỉ tính toán khi có ảnh
    if (widget.imageBase64 == null) return;

    // Sử dụng context.size để lấy kích thước một cách an toàn
    final size = context.size;
    if (size == null) return;

    final containerWidth = size.width;
    final containerHeight = size.height;

    // Tính toán delta
    final dx = details.delta.dx / (containerWidth / 2);
    final dy = details.delta.dy / (containerHeight / 2);

    // Cập nhật giá trị tạm thời ngay lập tức
    _currentAlignment = Alignment(
      (_currentAlignment.x + dx).clamp(-1.0, 1.0),
      (_currentAlignment.y + dy).clamp(-1.0, 1.0),
    );

    // Nếu chưa có lần cập nhật nào được lên lịch, hãy lên lịch một lần
    if (!_isUpdateScheduled) {
      _isUpdateScheduled = true;
      // Lên lịch để thực thi ở vòng lặp sự kiện tiếp theo
      Future.delayed(Duration.zero, () {
        // Kiểm tra xem widget còn tồn tại không
        if (mounted) {
          // Bây giờ mới cập nhật Notifier để trigger rebuild
          _alignmentNotifier.value = _currentAlignment;
          // Gọi callback cho widget cha
          widget.onAlignmentChanged(_currentAlignment);
          // Reset cờ để cho phép lần cập nhật tiếp theo được lên lịch
          _isUpdateScheduled = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Không cần LayoutBuilder nữa, vì context.size đã có sẵn trong build method
    // của một stateful widget sau khi layout lần đầu.
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: GestureDetector(
        onPanUpdate: _handlePanUpdate, // Gọi hàm xử lý đã tách riêng
        child: ValueListenableBuilder<Alignment>(
          valueListenable: _alignmentNotifier,
          builder: (context, alignment, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFF8BBD0),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFFCE4EC),
                  ),
                  child:
                      widget.imageBase64 != null
                          ? Builder(
                            builder: (context) {
                              try {
                                String cleanBase64 = widget.imageBase64!;
                                if (cleanBase64.contains(',')) {
                                  cleanBase64 = cleanBase64.split(',').last;
                                }
                                final bytes = base64Decode(
                                  cleanBase64.replaceAll(RegExp(r'\s+'), ''),
                                );
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.memory(
                                    bytes,
                                    fit: BoxFit.cover,
                                    alignment: alignment,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                );
                              } catch (e) {
                                return const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 40,
                                    color: Colors.red,
                                  ),
                                );
                              }
                            },
                          )
                          : const Center(
                            child: Icon(
                              Icons.photo_size_select_actual_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                ),
                if (widget.imageBase64 != null)
                  IgnorePointer(
                    child: Icon(
                      Icons.open_with_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 40,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
