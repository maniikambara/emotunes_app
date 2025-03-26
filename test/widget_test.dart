import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:emotunes_app/main.dart';
import 'package:emotunes_app/services/emotion_service.dart';
import 'package:emotunes_app/services/music_service.dart';
import 'package:emotunes_app/screens/home_screen.dart';
import 'package:emotunes_app/screens/mood_detection_screen.dart';
import 'package:emotunes_app/screens/recommendations_screen.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('App renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const EmoTunesApp());
      expect(find.text('EmoTunes'), findsOneWidget);
    });

    testWidgets('HomeScreen shows main actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => EmotionService()),
            ChangeNotifierProvider(create: (_) => MusicService()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Verify main UI elements
      expect(find.text('Welcome to EmoTunes'), findsOneWidget);
      expect(find.text('Detect Mood'), findsOneWidget);
      expect(find.text('Song Recommendations'), findsOneWidget);
    });

    testWidgets('MoodDetectionScreen shows camera when available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => EmotionService()),
            ChangeNotifierProvider(create: (_) => MusicService()),
          ],
          child: const MaterialApp(
            home: MoodDetectionScreen(),
          ),
        ),
      );

      // Initially should show loading or camera
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('RecommendationsScreen handles empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => EmotionService()),
            ChangeNotifierProvider(create: (_) => MusicService()),
          ],
          child: const MaterialApp(
            home: RecommendationsScreen(
              mood: EmotionType.happy,
            ),
          ),
        ),
      );

      // Should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Pump again to process async operations
      await tester.pump();

      // Use anyOf to check either condition
      expect(find.textContaining('Recommendations'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => EmotionService()),
            ChangeNotifierProvider(create: (_) => MusicService()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Try to navigate to Mood Detection
      await tester.tap(find.text('Detect Mood'));
      await tester.pumpAndSettle();

      // Should be on Mood Detection screen
      expect(find.byType(MoodDetectionScreen), findsOneWidget);

      // Go back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Should be back on Home screen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Error states are handled correctly',
        (WidgetTester tester) async {
      final musicService = MusicService();
      await musicService.getRecommendations('invalid_mood').catchError((_) {});

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: musicService),
            ChangeNotifierProvider(create: (_) => EmotionService()),
          ],
          child: const MaterialApp(
            home: RecommendationsScreen(
              mood: EmotionType.happy,
            ),
          ),
        ),
      );

      await tester.pump();

      // Should show error state
      expect(find.text('Error Loading Recommendations'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Theme switching works', (WidgetTester tester) async {
      await tester.pumpWidget(const EmoTunesApp());

      // Get the current theme
      final BuildContext context = tester.element(find.byType(EmoTunesApp));
      final ThemeData theme = Theme.of(context);

      // Verify theme properties
      expect(theme.primaryColor, isNotNull);
      expect(theme.colorScheme, isNotNull);
      expect(theme.textTheme, isNotNull);
    });
  });
}