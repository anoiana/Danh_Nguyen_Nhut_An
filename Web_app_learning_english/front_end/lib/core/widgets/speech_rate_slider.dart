import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untitled/api/tts_service.dart';

/// Widget hiển thị slider để điều chỉnh tốc độ đọc TTS.
/// Có thể sử dụng như một BottomSheet hoặc Dialog.
class SpeechRateSlider extends StatefulWidget {
  final TextToSpeechService ttsService;

  const SpeechRateSlider({Key? key, required this.ttsService})
    : super(key: key);

  @override
  State<SpeechRateSlider> createState() => _SpeechRateSliderState();
}

class _SpeechRateSliderState extends State<SpeechRateSlider> {
  late double _currentRate;
  StreamSubscription<double>? _subscription;

  static const Color primaryPink = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _currentRate = widget.ttsService.speechRate;

    // Lắng nghe thay đổi từ service
    _subscription = widget.ttsService.speechRateStream.listen((rate) {
      if (mounted) {
        setState(() => _currentRate = rate);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _getSpeedLabel(double rate) {
    if (rate <= 0.25) return 'Rất chậm';
    if (rate <= 0.4) return 'Chậm';
    if (rate <= 0.6) return 'Bình thường';
    if (rate <= 0.8) return 'Nhanh';
    return 'Rất nhanh';
  }

  IconData _getSpeedIcon(double rate) {
    if (rate <= 0.4) return Icons.speed;
    if (rate <= 0.6) return Icons.play_arrow;
    return Icons.fast_forward;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hiển thị tốc độ hiện tại
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getSpeedIcon(_currentRate), color: primaryPink, size: 28),
            const SizedBox(width: 8),
            Text(
              _getSpeedLabel(_currentRate),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(_currentRate * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryPink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Slider điều chỉnh tốc độ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.slow_motion_video, size: 20, color: Colors.grey),
              Expanded(
                child: Slider(
                  value: _currentRate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 18,
                  activeColor: primaryPink,
                  inactiveColor: primaryPink.withOpacity(0.2),
                  label: '${(_currentRate * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() => _currentRate = value);
                    widget.ttsService.setSpeechRate(value);
                  },
                ),
              ),
              const Icon(Icons.speed, size: 20, color: Colors.grey),
            ],
          ),
        ),

        // Các nút preset tốc độ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPresetButton('0.25x', 0.25),
              _buildPresetButton('0.5x', 0.5),
              _buildPresetButton('0.75x', 0.75),
              _buildPresetButton('1.0x', 1.0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, double rate) {
    final isSelected = (_currentRate - rate).abs() < 0.05;
    return TextButton(
      onPressed: () {
        setState(() => _currentRate = rate);
        widget.ttsService.setSpeechRate(rate);
      },
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? primaryPink : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/// Hiển thị BottomSheet để điều chỉnh tốc độ đọc.
/// Gọi hàm này từ bất kỳ màn hình nào có TTS.
void showSpeechRateBottomSheet(
  BuildContext context,
  TextToSpeechService ttsService,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 32,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 20),

              // Tiêu đề
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.record_voice_over, color: Color(0xFFE91E63)),
                  SizedBox(width: 8),
                  Text(
                    'Tốc độ đọc',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Slider widget
              SpeechRateSlider(ttsService: ttsService),

              const SizedBox(height: 16),

              // Nút thử nghiệm
              ElevatedButton.icon(
                onPressed: () {
                  ttsService.speak(
                    'This is a test of the current speech rate.',
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Thử nghiệm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
  );
}
