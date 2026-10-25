import 'package:flutter/material.dart';
import '../../strings/app_strings.dart';

class UnsupportedCard extends StatelessWidget {
  const UnsupportedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.unsupportedHeadline,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.unsupportedBody,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}
