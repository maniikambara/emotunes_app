import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Song {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String? previewUrl;
  final String externalUrl;
  final int durationMs;
  final Map<String, dynamic>? audioFeatures;
  final String? predictedMood;

  Song({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    required this.externalUrl, required this.durationMs, this.previewUrl,
    this.audioFeatures,
    this.predictedMood,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      name: json['name'],
      artist: json['artist'],
      album: json['album'],
      previewUrl: json['preview_url'],
      externalUrl: json['external_url'],
      durationMs: json['duration_ms'],
      audioFeatures: json['audio_features'],
      predictedMood: json['predicted_mood'],
    );
  }
}

class MusicService extends ChangeNotifier {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  List<Song> _recommendations = [];
  String? _error;
  bool _isLoading = false;

  List<Song> get recommendations => _recommendations;
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> getRecommendations(String mood, {int limit = 10}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$_baseUrl/recommendations?mood=$mood&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _recommendations = data.map((json) => Song.fromJson(json)).toList();
        _error = null;
      } else {
        _error = 'Failed to get recommendations: ${response.statusCode}';
        _recommendations = [];
      }
    } catch (e) {
      _error = 'Error getting recommendations: $e';
      _recommendations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> analyzeSong(String songUrl) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$_baseUrl/analyze_song'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'song_url': songUrl}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _error = 'Failed to analyze song: ${response.statusCode}';
        return null;
      }
    } catch (e) {
      _error = 'Error analyzing song: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}