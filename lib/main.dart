import 'package:flutter/material.dart';
import 'package:sahubyte_user/res/app_ui.dart';
import 'package:sahubyte_user/view/splash_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sahubyte',
      theme: buildAppTheme(),
      home: const SplashView(),
    );
  }
}
