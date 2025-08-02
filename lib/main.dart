import 'package:chat_app/presentation/screens/chat_screen.dart';
import 'package:chat_app/presentation/screens/home_screen.dart';
import 'package:chat_app/presentation/screens/login_screen.dart';
import 'package:chat_app/presentation/screens/profile_screen.dart';
import 'package:chat_app/presentation/screens/register_screen.dart';
import 'package:chat_app/presentation/screens/splash_screen.dart';
import 'package:chat_app/presentation/screens/users_list_screen.dart';
import 'package:chat_app/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Production entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firestore offline support
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(AppRoot(auth: FirebaseAuth.instance));
}

/// Root container that allows injecting a FirebaseAuth instance (real or mock).
class AppRoot extends StatelessWidget {
  final FirebaseAuth auth;

  const AppRoot({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MyApp(auth: auth);
  }
}

class MyApp extends StatelessWidget {
  final FirebaseAuth auth;

  const MyApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Chat App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Chat',
        primaryColor: app_main_color,
        colorScheme: ColorScheme.fromSeed(seedColor: app_main_color),
      ),
      initialRoute: auth.currentUser == null ? Routes.login : Routes.home,
      routes: {
        Routes.splash: (context) => SplashScreen(),
        Routes.login: (context) => const LoginScreen(),
        Routes.register: (context) => const RegisterScreen(),
        Routes.users: (context) => const UsersListScreen(),
        Routes.chat: (context) => const ChatScreen(),
        Routes.profile: (context) => const ProfileScreen(),
        Routes.home: (context) => const HomeScreen(),
      },
    );
  }
}

class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const users = '/users';
  static const chat = '/chat';
  static const profile = '/profile';
  static const home = '/home';
}
