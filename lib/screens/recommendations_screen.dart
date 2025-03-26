import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/emotion_service.dart';
import '../services/music_service.dart';
import 'package:just_audio/just_audio.dart';

class RecommendationsScreen extends StatefulWidget {
  final EmotionType mood;

  const RecommendationsScreen({
    required this.mood, super.key,
  });

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final musicService = Provider.of<MusicService>(context, listen: false);
    await musicService.getRecommendations(
      widget.mood.toString().split('.').last,
      limit: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Songs'),
        centerTitle: true,
      ),
      body: Consumer<MusicService>(
        builder: (context, musicService, child) {
          if (musicService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (musicService.error != null) {
            return _buildErrorView(musicService);
          }

          if (musicService.recommendations.isEmpty) {
            return _buildEmptyView();
          }

          return _buildRecommendationsList(musicService);
        },
      ),
    );
  }

  Widget _buildErrorView(MusicService musicService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Recommendations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              musicService.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRecommendations,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Recommendations Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try detecting your mood again or check back later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(MusicService musicService) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: musicService.recommendations.length,
      itemBuilder: (context, index) {
        final song = musicService.recommendations[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              song.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  song.album,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (song.audioFeatures != null)
                  _buildAudioFeatures(song.audioFeatures!),
              ],
            ),
            trailing: song.previewUrl != null
                ? _buildPlayButton(song)
                : const Icon(Icons.music_off),
            onTap: () {
              // Open external URL in browser
              // TODO: Implement URL launcher
            },
          ),
        );
      },
    );
  }

  Widget _buildAudioFeatures(Map<String, dynamic> features) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _buildFeatureChip('Energy', features['energy']),
          _buildFeatureChip('Valence', features['valence']),
          _buildFeatureChip('Danceability', features['danceability']),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, double value) {
    return Chip(
      label: Text(
        '$label: ${(value * 100).toInt()}%',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
    );
  }

  Widget _buildPlayButton(Song song) {
    final isPlaying = _currentlyPlayingId == song.id;

    return IconButton(
      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
      onPressed: () => _handlePlayPress(song),
    );
  }

  Future<void> _handlePlayPress(Song song) async {
    if (_currentlyPlayingId == song.id) {
      // Stop current preview
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingId = null);
    } else {
      // Play new preview
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setUrl(song.previewUrl!);
        await _audioPlayer.play();
        setState(() => _currentlyPlayingId = song.id);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing preview: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}