import 'package:emotunes_app/screens/login_screen.dart';
import 'package:emotunes_app/screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/emotion_service.dart';
import 'mood_detection_screen.dart';
import 'recommendations_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('EmoTunes'),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.music_note,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Text
                    Text(
                      'Welcome to EmoTunes',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discover music that matches your mood',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Main Actions
                    _buildActionCard(
                      context,
                      'Login',
                      'Access your account',
                      Icons.login,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context,
                      'Sign Up',
                      'Create a new account',
                      Icons.person_add,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      context,
                      'Detect Mood',
                      'Let us analyze your mood through facial expression',
                      Icons.face,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MoodDetectionScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context,
                      'Song Recommendations',
                      'View your personalized music recommendations',
                      Icons.music_note,
                      () {
                        final emotionService = context.read<EmotionService>();
                        if (emotionService.currentEmotion != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecommendationsScreen(
                                mood: emotionService.currentEmotion!,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please detect your mood first'),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Current Mood Display
                    Consumer<EmotionService>(
                      builder: (context, emotionService, child) {
                        final currentEmotion = emotionService.currentEmotion;
                        if (currentEmotion == null) {
                          return const SizedBox.shrink();
                        }
                        
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Current Mood',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentEmotion.toString().split('.').last.toUpperCase(),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}