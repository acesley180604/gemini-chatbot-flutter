import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging
  _initializeLogging();
  
  // Load environment configuration
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}

void _initializeLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final message = '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}';
    
    if (record.level >= Level.SEVERE) {
      debugPrint('🔴 $message');
    } else if (record.level >= Level.WARNING) {
      debugPrint('🟡 $message');
    } else if (record.level >= Level.INFO) {
      debugPrint('🔵 $message');
    } else {
      debugPrint('⚪ $message');
    }
    
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('Stack trace: ${record.stackTrace}');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Chatbot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}