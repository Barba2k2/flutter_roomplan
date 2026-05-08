import 'package:example/views/scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:example/viewmodels/home_view_model.dart'; // Import HomeViewModel

/// The home page of the example app.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("RoomPlan Flutter"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<HomeViewModel>( // Use Consumer to access ViewModel
            builder: (context, viewModel, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.view_in_ar, size: 80, color: Colors.blue.shade600),
                  const SizedBox(height: 24),
                  Text(
                    'RoomPlan Scanner',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Capture precise measurements of your environment using ARKit technology. Press the button below to start scanning.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () {
                      viewModel.navigateToScannerPage(context); // Call ViewModel method
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ScannerPage()),
                      );
                    },
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Start Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Requirements',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          viewModel.isRoomPlanSupported
                              ? 'RoomPlan is supported on this device.'
                              : 'RoomPlan is NOT supported on this device. Requires iOS 16+ and LiDAR.',
                          style: TextStyle(
                            color: viewModel.isRoomPlanSupported ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
