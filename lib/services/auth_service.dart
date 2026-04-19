import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final auth = FirebaseAuth.instance;

  // Signup
  Future signup(String email, String password) async {
    var res = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // token lo
    String? token = await FirebaseMessaging.instance.getToken();

    //Firestore me save
    await FirebaseFirestore.instance
        .collection("users")
        .doc(res.user!.uid)
        .set({
      "uid": res.user!.uid,
      "email": res.user!.email,
      "token": token,
    });

    return res.user;
  }

  //Login
  Future login(String email, String password) async {
    var res = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    //token update karo
    String? token = await FirebaseMessaging.instance.getToken();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(res.user!.uid)
        .update({
      "token": token,
    });

    return res.user;
  }

  // Logout
  Future logout() async {
    await auth.signOut();
  }
}