import 'package:flutter/material.dart';
import '../../api/tts_service.dart';
import 'speech_rate_slider.dart';

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
