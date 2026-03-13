import 'package:align/SignUpScreen.dart';
import 'package:align/navigator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();


  Get.put(NavigationController());

  runApp(
    GetMaterialApp(
      title: 'Align',
      debugShowCheckedModeBanner: false,
      home: SignupScreen(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SignupScreen(),
    );
  }
}