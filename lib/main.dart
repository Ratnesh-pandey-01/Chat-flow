import 'package:chat_flow/firebase_options.dart';
import 'package:chat_flow/providers/theme_provider.dart';
import 'package:chat_flow/services/fcm_service.dart';
import 'package:chat_flow/widgets/AuthCheck.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FCMService().init();

  runApp(
    //ChangeNotifierProvider(create: (context)=>UserProvider(),
    MultiProvider(
      providers: [
        //ChangeNotifierProvider(create: (context)=>UserProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      theme: themeProvider.isdark ? ThemeData.dark() : ThemeData.light(),

      // theme:
      //  ThemeData(
      //   textTheme: GoogleFonts.anekDevanagariTextTheme()),
      debugShowCheckedModeBanner: false,

      home:
        Authcheck(),
    );
  }
}
