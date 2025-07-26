import 'package:chat_app/presentation/screens/home_screen.dart';
import 'package:chat_app/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/users_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Chat',
        primaryColor: app_main_color,
        colorScheme: ColorScheme.fromSeed(seedColor: app_main_color),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/users': (context) => const UsersListScreen(),
        '/chat': (context) => const ChatScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
