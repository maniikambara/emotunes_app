import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'screens/home_screen.dart';
import 'themes/app_theme.dart';
import 'services/emotion_service.dart';
import 'services/music_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize services
  final emotionService = EmotionService();
  await emotionService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => emotionService),
        ChangeNotifierProvider(create: (_) => MusicService()),
      ],
      child: const EmoTunesApp(),
    ),
  );
}

class EmoTunesApp extends StatelessWidget {
  const EmoTunesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmoTunes',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}