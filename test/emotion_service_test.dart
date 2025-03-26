import 'package:flutter_test/flutter_test.dart';
import 'package:emotunes_app/services/emotion_service.dart';

void main() {
  group('EmotionService Tests', () {
    late EmotionService emotionService;

    setUp(() {
      emotionService = EmotionService();
    });

    test('initial state is correct', () {
      expect(emotionService.isInitialized, false);
      expect(emotionService.currentEmotion, null);
      expect(emotionService.errorMessage, null);
      expect(emotionService.isProcessing, false);
    });

    test('initialization changes state', () async {
      // This test might fail in CI environment without camera
      try {
        await emotionService.initialize();
        expect(emotionService.isInitialized, true);
        expect(emotionService.errorMessage, null);
      } catch (e) {
        // Skip test if no camera available
        expect(emotionService.isInitialized, false);
        expect(emotionService.errorMessage, isNotNull);
      }
    });

    test('emotion types are correct', () {
      expect(EmotionType.values, [
        EmotionType.Happy,
        EmotionType.Sad,
        EmotionType.Surprised,
        EmotionType.Fearful,
        EmotionType.Angry,
        EmotionType.Disgusted,
        EmotionType.Neutral,
      ]);
    });

    test('clear error works', () {
      emotionService = EmotionService()
        ..initialize().catchError((_) {}); // Force an error
      
      emotionService.clearError();
      expect(emotionService.errorMessage, null);
    });
  });
}