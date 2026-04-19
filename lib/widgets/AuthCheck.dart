import 'package:chat_flow/screens/auth/login_screen.dart';
import 'package:chat_flow/screens/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Authcheck extends StatelessWidget {
  const Authcheck({super.key});

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return HomeScreen();
    } else {
      return LoginScreen();
    }
  }
}
