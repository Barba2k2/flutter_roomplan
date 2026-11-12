import 'package:flutter/material.dart';
import '../../helpers/remaining_time_helper.dart';
import '../../strings/app_strings.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.fraction, this.remaining});

  final double fraction;
  final Duration? remaining;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final remainingText = remaining == null
        ? AppStrings.progressPreparing
        : RemainingTimeHelper.format(remaining!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.progressTitle, style: textTheme.titleMedium),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: fraction),
            const SizedBox(height: 8),
            Text('${(fraction * 100).round()}%  -  $remainingText'),
          ],
        ),
      ),
    );
  }
}
