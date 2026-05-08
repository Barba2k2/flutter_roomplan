import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:example/viewmodels/advanced_scanning_view_model.dart';
import 'package:example/viewmodels/home_view_model.dart';
import 'package:example/viewmodels/object_capture_view_model.dart';
import 'package:example/viewmodels/scanner_view_model.dart';
import 'package:example/views/advanced_scanning_page.dart';
import 'package:example/views/home_page.dart';
import 'package:example/views/object_capture_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apple Camera APIs Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HomeViewModel()),
          ChangeNotifierProvider(create: (_) => ScannerViewModel()),
          ChangeNotifierProvider(create: (_) => AdvancedScanningViewModel()),
          ChangeNotifierProvider(create: (_) => ObjectCaptureViewModel()),
        ],
        child: const MainNavigationPage(),
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    AdvancedScanningPage(),
    ObjectCapturePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'RoomPlan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_input_antenna),
            label: 'Advanced',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_in_ar),
            label: 'Object Capture',
          ),
        ],
      ),
    );
  }
}
