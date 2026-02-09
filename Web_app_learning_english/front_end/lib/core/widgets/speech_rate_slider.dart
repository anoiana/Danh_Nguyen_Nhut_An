import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untitled/api/tts_service.dart';

/// A slider widget for adjusting Text-to-Speech (TTS) rate.
/// Can be used within a BottomSheet or Dialog.
class SpeechRateSlider extends StatefulWidget {
  final TextToSpeechService ttsService;

  const SpeechRateSlider({super.key, required this.ttsService});

  @override
  State<SpeechRateSlider> createState() => _SpeechRateSliderState();
}

class _SpeechRateSliderState extends State<SpeechRateSlider> {
  late double _currentRate;
  StreamSubscription<double>? _subscription;

  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _textDark = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _currentRate = widget.ttsService.speechRate;

    // Listen for rate changes from the service
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
    if (rate <= 0.25) return 'Very Slow';
    if (rate <= 0.4) return 'Slow';
    if (rate <= 0.6) return 'Normal';
    if (rate <= 0.8) return 'Fast';
    return 'Very Fast';
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
        _buildCurrentRateDisplay(),
        const SizedBox(height: 16),
        _buildSliderControls(),
        const SizedBox(height: 16),
        _buildPresetButtons(),
      ],
    );
  }

  Widget _buildCurrentRateDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_getSpeedIcon(_currentRate), color: _primaryPink, size: 28),
        const SizedBox(width: 8),
        Text(
          _getSpeedLabel(_currentRate),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _primaryPink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${(_currentRate * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _primaryPink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderControls() {
    return Padding(
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
              activeColor: _primaryPink,
              inactiveColor: _primaryPink.withOpacity(0.2),
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
    );
  }

  Widget _buildPresetButtons() {
    return Padding(
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
        backgroundColor: isSelected ? _primaryPink : Colors.grey.shade200,
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

/// Shows a BottomSheet to adjust TTS speech rate.
/// Can be called from any screen with TTS functionality.
void showSpeechRateBottomSheet(
  BuildContext context,
  TextToSpeechService ttsService,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SpeechRateBottomSheet(ttsService: ttsService),
  );
}

class _SpeechRateBottomSheet extends StatelessWidget {
  final TextToSpeechService ttsService;

  const _SpeechRateBottomSheet({required this.ttsService});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 24),
          SpeechRateSlider(ttsService: ttsService),
          const SizedBox(height: 16),
          _buildTestButton(),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.record_voice_over, color: Color(0xFFE91E63)),
        SizedBox(width: 8),
        Text(
          'Reading Speed',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton() {
    return ElevatedButton.icon(
      onPressed: () {
        ttsService.speak('This is a test of the current speech rate.');
      },
      icon: const Icon(Icons.play_arrow),
      label: const Text('Test Voice'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
