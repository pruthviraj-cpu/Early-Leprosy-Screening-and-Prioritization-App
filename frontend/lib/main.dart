import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/chat_message.dart';
import 'models/diagnosis_result.dart';
import 'models/user_profile.dart';

import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/chat.dart';
import 'services/cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Initialize Hive
  await Hive.initFlutter();

  // 🔹 Register adapters
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(DiagnosisResultAdapter());
  Hive.registerAdapter(UserProfileAdapter());

  // 🔹 Open boxes (THIS WAS MISSING)
  await Hive.openBox<ChatMessage>('chats');
  await Hive.openBox<UserProfile>('profile');
  await Hive.openBox<DiagnosisResult>('diagnosis');
  await CacheService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: 'login',
      routes: {
        'login': (_) => MyLogin(),
        'register': (_) => MyRegister(),
        'home': (_) => const HomePage(),
        'chat': (_) => const ChatScreen(),
      },
    );
  }
}
