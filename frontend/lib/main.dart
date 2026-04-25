import 'package:flutter/material.dart';
import 'package:frontend/services/secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'features/chat/model/chat_message.dart';
import 'models/diagnosis_result.dart';
import 'features/profile/model/user_profile.dart';

import 'models/pending_diagnosis.dart';
import 'services/diagnosis_cache_service.dart';

// import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/register.dart';
// import 'screens/chat.dart';
// import 'services/cache_service.dart';

import 'features/profile/screen/profile_screen.dart';

import 'features/navigation/bottom_navigation.dart';
import 'features/navigation/doctor_navigation.dart';

import 'screens/doctor_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(DiagnosisResultAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(PendingDiagnosisAdapter());

  await Hive.openBox<UserProfile>('profile');
  await Hive.openBox<DiagnosisResult>('diagnosis');
  await DiagnosisCacheService.init();

  final token = await SecureStorage.getToken();
  final role = await SecureStorage.getUserRole();

  runApp(MyApp(isLoggedIn: token != null, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? role;

  const MyApp({super.key, required this.isLoggedIn, this.role});

  String _getInitialRoute() {
    if (!isLoggedIn) return 'login';

    if (role == 'doctor') return 'doctor_main';

    return 'main';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: _getInitialRoute(),
      routes: {
        'login': (_) => MyLogin(),
        'register': (_) => MyRegister(),

        'main': (context) {
          final index = ModalRoute.of(context)?.settings.arguments as int? ?? 0;
          return BottomNavScreen(initialIndex: index);
        },

        'doctor_main': (context) {
          final index = ModalRoute.of(context)?.settings.arguments as int? ?? 0;
          return DoctorBottomNavScreen(initialIndex: index);
        },

        "doctor_details": (context) {
          final patient =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;

          return DoctorHomePage(patient: patient);
        },
      },
    );
  }
}
