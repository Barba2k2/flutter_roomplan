import 'package:flutter/material.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import '../../strings/app_strings.dart';

class LimitsCard extends StatelessWidget {
  const LimitsCard({super.key, required this.limits});

  final ObjectCaptureLimits limits;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              AppStrings.limitsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            title: const Text(AppStrings.limitsMaxImages),
            trailing: Text('${limits.maxImages}'),
          ),
          ListTile(
            title: const Text(AppStrings.limitsMaxDimension),
            trailing: Text('${limits.maxImageDimension}'),
          ),
        ],
      ),
    );
  }
}
