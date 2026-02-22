import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/chat/model/chat_message.dart';
import 'models/diagnosis_result.dart';
import 'features/profile/model/user_profile.dart';

// import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/register.dart';
// import 'screens/chat.dart';
// import 'services/cache_service.dart';

import 'features/navigation/bottom_navigation.dart';
import 'features/navigation/doctor_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(DiagnosisResultAdapter());
  Hive.registerAdapter(UserProfileAdapter());

  // 🔹 Only global boxes
  await Hive.openBox<UserProfile>('profile');
  await Hive.openBox<DiagnosisResult>('diagnosis');

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
        // 'home': (_) => const HomePage(),
        // 'chat': (_) => const ChatScreen(),
        'main': (_) => const BottomNavScreen(), // 👈
        'doctor_main': (_) => const DoctorBottomNavScreen(), // 🎉
      },
    );
  }
}
