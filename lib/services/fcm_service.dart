import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // // Init function (app start pe call hoga)
  // Future init() async {
  //   // 1. Permission lena
  //   await _fcm.requestPermission();

  //   // 2. Token lena
  //   String? token = await _fcm.getToken();
  //   print("FCM TOKEN: $token");

  //   // 3. Foreground message listen
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print(" Title: ${message.notification?.title}");
  //     print("Body: ${message.notification?.body}");
  //   });
  // }

  // // Token alag se lene ke liye (AuthService me use hoga)
  // Future<String?> getToken() async {
  //   return await _fcm.getToken();
  // }
  Future init() async {
  await _fcm.requestPermission();

  String? token = await _fcm.getToken();
  print("FCM TOKEN: $token");

  final user = FirebaseAuth.instance.currentUser;

  if (user != null && token != null) {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({
      "fcmToken": token,
    }, SetOptions(merge: true));
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
  });
}
}