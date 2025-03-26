import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../services/emotion_service.dart';
import 'recommendations_screen.dart';

class MoodDetectionScreen extends StatefulWidget {
  const MoodDetectionScreen({super.key});

  @override
  State<MoodDetectionScreen> createState() => _MoodDetectionScreenState();
}

class _MoodDetectionScreenState extends State<MoodDetectionScreen> {
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final emotionService = Provider.of<EmotionService>(context, listen: false);
    if (!emotionService.isInitialized) {
      await emotionService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Detection'),
        centerTitle: true,
      ),
      body: Consumer<EmotionService>(
        builder: (context, emotionService, child) {
          if (emotionService.errorMessage != null) {
            return _buildErrorView(emotionService.errorMessage!);
          }

          if (!emotionService.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera Preview
                    CameraPreview(emotionService.cameraController!),
                    
                    // Overlay
                    _buildOverlay(),
                    
                    // Loading indicator
                    if (_isAnalyzing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
              // Controls
              _buildControls(emotionService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorView(String error) {
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
              'Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Face outline guide
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          // Instructions
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.black54,
              child: const Text(
                'Position your face within the circle',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(EmotionService emotionService) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emotionService.currentEmotion != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Detected Mood: ${emotionService.currentEmotion.toString().split('.').last.toUpperCase()}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _isAnalyzing ? null : () => _detectEmotion(emotionService),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(_isAnalyzing ? 'Analyzing...' : 'Detect Mood'),
              ),
              if (emotionService.currentEmotion != null)
                ElevatedButton(
                  onPressed: () => _showRecommendations(emotionService),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Get Recommendations'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _detectEmotion(EmotionService emotionService) async {
    if (_isAnalyzing) {
      return;
    }

    setState(() => _isAnalyzing = true);
    
    try {
      await emotionService.detectEmotion();
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _showRecommendations(EmotionService emotionService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationsScreen(
          mood: emotionService.currentEmotion!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}