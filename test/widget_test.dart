import 'package:chat_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Dummy initialization so firebase_core doesn't fail.
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test',
        appId: '1:123:android:test',
        messagingSenderId: 'test',
        projectId: 'test',
      ),
    );
  });

  testWidgets('App builds with a signed-in mock user', (WidgetTester tester) async {
    final mockUser = MockUser(
      isAnonymous: false,
      uid: 'uid123',
      email: 'test@example.com',
    );
    final mockAuth = MockFirebaseAuth(mockUser: mockUser);

    await tester.pumpWidget(AppRoot(auth: mockAuth));
    await tester.pumpAndSettle();

    // Sanity: root rendered
    expect(find.byType(MaterialApp), findsOneWidget);
    // Since user is signed in, initial route is home; adjust if HomeScreen shows specific text
    expect(find.textContaining('Home'), findsWidgets);
  });

  testWidgets('App shows login when no user is signed in', (WidgetTester tester) async {
    final mockAuth = MockFirebaseAuth(); // no user

    await tester.pumpWidget(AppRoot(auth: mockAuth));
    await tester.pumpAndSettle();

    // Expect login screen; adjust to actual login UI text/element
    expect(find.textContaining('Login'), findsWidgets);
  });
}
