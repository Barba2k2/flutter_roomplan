import 'package:flutter/material.dart';
import 'package:example/views/home_page.dart'; // Import HomePage
import 'package:provider/provider.dart'; // Import provider
import 'package:example/viewmodels/scanner_view_model.dart'; // Import ScannerViewModel
import 'package:example/viewmodels/home_view_model.dart'; // Import HomeViewModel

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomPlan Flutter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MultiProvider( // Use MultiProvider for multiple ViewModels
        providers: [
          ChangeNotifierProvider(create: (context) => HomeViewModel()),
          ChangeNotifierProvider(create: (context) => ScannerViewModel()),
        ],
        child: const HomePage(), // Set HomePage as the home
      ),
    );
  }
}
