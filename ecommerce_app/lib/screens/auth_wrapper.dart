import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerce_app/screens/login_screen.dart';
import 'package:ecommerce_app/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. We use a StreamBuilder to listen for auth changes
    return StreamBuilder<User?>(
      // 2. This is the stream from Firebase
      stream: FirebaseAuth.instance.authStateChanges(),
      // 3. The builder runs every time the auth state changes
      builder: (context, snapshot) {
        // 4. If the snapshot is still loading, show a spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 5. If the snapshot has data, a user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen(); // Show the home screen
        }

        // If user is not logged in, show LoginScreen
        return const LoginScreen(); // Show the login screen
      },
    );
  }
}