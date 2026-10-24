import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class ConfigurationDialog extends StatefulWidget {
  final ScanConfiguration currentConfig;
  final ValueChanged<ScanConfiguration> onConfigurationChanged;

  const ConfigurationDialog({
    super.key,
    required this.currentConfig,
    required this.onConfigurationChanged,
  });

  @override
  State<ConfigurationDialog> createState() => _ConfigurationDialogState();
}

class _ConfigurationDialogState extends State<ConfigurationDialog> {
  late ScanConfiguration _config;

  @override
  void initState() {
    super.initState();
    _config = widget.currentConfig;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quality Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quality Level',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...ScanQuality.values.map(
                      (quality) => RadioListTile<ScanQuality>(
                        title: Text(quality.name),
                        subtitle: Text(quality.description),
                        value: quality,
                        groupValue: _config.quality,
                        onChanged: (value) {
                          setState(() {
                            _config = _config.copyWith(quality: value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Feature Toggles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detection Features',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Real-time Updates'),
                      subtitle: const Text('Get updates during scanning'),
                      value: _config.enableRealtimeUpdates,
                      onChanged: (value) {
                        setState(() {
                          _config = _config.copyWith(
                            enableRealtimeUpdates: value,
                          );
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Detect Furniture'),
                      subtitle: const Text('Include furniture in scan results'),
                      value: _config.detectFurniture,
                      onChanged: (value) {
                        setState(() {
                          _config = _config.copyWith(detectFurniture: value);
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Detect Doors'),
                      subtitle: const Text('Include doors in scan results'),
                      value: _config.detectDoors,
                      onChanged: (value) {
                        setState(() {
                          _config = _config.copyWith(detectDoors: value);
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Detect Windows'),
                      subtitle: const Text('Include windows in scan results'),
                      value: _config.detectWindows,
                      onChanged: (value) {
                        setState(() {
                          _config = _config.copyWith(detectWindows: value);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Preset Buttons
            const SizedBox(height: 16),
            Text(
              'Quick Presets',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _config = const ScanConfiguration.fast();
                    });
                  },
                  child: const Text('Fast'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _config = const ScanConfiguration.accurate();
                    });
                  },
                  child: const Text('Accurate'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _config = const ScanConfiguration.minimal();
                    });
                  },
                  child: const Text('Minimal'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfigurationChanged(_config);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
