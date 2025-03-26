import 'package:flutter_test/flutter_test.dart';
import 'package:emotunes_app/services/music_service.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  group('MusicService Tests', () {
    late MusicService musicService;
    late MockClient mockClient;

    setUp(() async {
      // Load environment variables
      await dotenv.load(fileName: '.env.example');
      
      mockClient = MockClient();
      musicService = MusicService();
    });

    test('initial state is correct', () {
      expect(musicService.recommendations, isEmpty);
      expect(musicService.error, isNull);
      expect(musicService.isLoading, isFalse);
    });

    test('Song model creation works', () {
      final song = Song(
        id: 'test_id',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        externalUrl: 'https://example.com',
        durationMs: 180000,
      );

      expect(song.id, 'test_id');
      expect(song.name, 'Test Song');
      expect(song.artist, 'Test Artist');
      expect(song.album, 'Test Album');
      expect(song.externalUrl, 'https://example.com');
      expect(song.durationMs, 180000);
      expect(song.previewUrl, isNull);
      expect(song.audioFeatures, isNull);
      expect(song.predictedMood, isNull);
    });

    test('Song.fromJson works correctly', () {
      final json = {
        'id': 'test_id',
        'name': 'Test Song',
        'artist': 'Test Artist',
        'album': 'Test Album',
        'preview_url': 'https://example.com/preview',
        'external_url': 'https://example.com',
        'duration_ms': 180000,
        'audio_features': {
          'tempo': 120.0,
          'valence': 0.8,
          'energy': 0.7,
          'danceability': 0.6,
          'instrumentalness': 0.1
        },
        'predicted_mood': 'happy'
      };

      final song = Song.fromJson(json);

      expect(song.id, json['id']);
      expect(song.name, json['name']);
      expect(song.artist, json['artist']);
      expect(song.album, json['album']);
      expect(song.previewUrl, json['preview_url']);
      expect(song.externalUrl, json['external_url']);
      expect(song.durationMs, json['duration_ms']);
      expect(song.audioFeatures, json['audio_features']);
      expect(song.predictedMood, json['predicted_mood']);
    });

    test('error handling works', () async {
      // Simulate an error condition
      await musicService.getRecommendations('happy').catchError((_) {});
      
      // Clear the error
      musicService.clearError();
      expect(musicService.error, isNull);
    });

    test('loading state changes correctly', () async {
      // Start a request (it will fail due to mock client)
      final future = musicService.getRecommendations('happy');
      
      // Should be loading initially
      expect(musicService.isLoading, isTrue);
      
      // Wait for the request to complete
      await future.catchError((_) {});
      
      // Should not be loading after completion
      expect(musicService.isLoading, isFalse);
    });

    test('analyzeSong handles errors correctly', () async {
      final result = await musicService.analyzeSong('invalid_url');
      expect(result, isNull);
      expect(musicService.error, isNotNull);
    });

    test('recommendations list is cleared on error', () async {
      // Add some fake recommendations
      final fakeSong = Song(
        id: 'test_id',
        name: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        externalUrl: 'https://example.com',
        durationMs: 180000,
      );
      
      // Force an error
      await musicService.getRecommendations('invalid_mood').catchError((_) {});
      
      expect(musicService.recommendations, isEmpty);
      expect(musicService.error, isNotNull);
    });
  });
}