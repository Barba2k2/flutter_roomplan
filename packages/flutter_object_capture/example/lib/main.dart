import 'package:flutter/material.dart';
import 'controllers/support_controller.dart';
import 'strings/app_strings.dart';
import 'views/support_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: SupportPage(
        controller: SupportController(),
      ),
    );
  }
}
