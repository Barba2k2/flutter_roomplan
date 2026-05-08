import 'package:flutter/material.dart';

/// Red-tinted tile that surfaces a failure message inline next to the rest of
/// a page's results.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: ListTile(
        leading: const Icon(Icons.error, color: Colors.red),
        title: const Text('Error'),
        subtitle: Text(message),
      ),
    );
  }
}
