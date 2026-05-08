import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';

/// Minimal demo for `flutter_object_capture`.
///
/// Verifies device support, lets the user trigger a guided `captureObject()`
/// session, and runs `reconstruct()` over the produced photo folder. The page
/// is intentionally barebones so it stays useful as the API evolves.
class ObjectCapturePage extends StatefulWidget {
  const ObjectCapturePage({super.key});

  @override
  State<ObjectCapturePage> createState() => _ObjectCapturePageState();
}

class _ObjectCapturePageState extends State<ObjectCapturePage> {
  Future<bool>? _isSupportedFuture;
  StreamSubscription<CaptureEvent>? _eventSubscription;
  CaptureEvent? _latestEvent;
  ObjectCaptureResult? _captureResult;
  PhotogrammetryResult? _reconstructionResult;
  String? _errorMessage;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _isSupportedFuture = FlutterObjectCapture.isSupported();
    _eventSubscription = FlutterObjectCapture.events.listen((event) {
      setState(() => _latestEvent = event);
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _runCapture() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _captureResult = null;
      _reconstructionResult = null;
    });
    try {
      final result = await FlutterObjectCapture.captureObject();
      setState(() => _captureResult = result);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _runReconstruct() async {
    final imagesPath = _captureResult?.imagesFolderPath;
    if (imagesPath == null) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _reconstructionResult = null;
    });
    try {
      final result = await FlutterObjectCapture.reconstruct(
        imagesPath: imagesPath,
        detailLevel: DetailLevel.medium,
      );
      setState(() => _reconstructionResult = result);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Object Capture')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            FutureBuilder<bool>(
              future: _isSupportedFuture,
              builder: (context, snapshot) {
                final supported = snapshot.data;
                final label = switch (supported) {
                  null => 'Checking device support…',
                  true => 'Object Capture supported',
                  false => 'Object Capture NOT supported on this device',
                };
                final color = switch (supported) {
                  null => Colors.grey,
                  true => Colors.green,
                  false => Colors.red,
                };
                return Card(
                  color: color.withValues(alpha: 0.1),
                  child: ListTile(
                    leading: Icon(Icons.camera_alt, color: color),
                    title: Text(label),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isBusy ? null : _runCapture,
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Capture object'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed:
                  (_isBusy || _captureResult == null) ? null : _runReconstruct,
              icon: const Icon(Icons.view_in_ar),
              label: const Text('Reconstruct USDZ'),
            ),
            if (_isBusy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 24),
            if (_latestEvent != null) _eventCard(_latestEvent!),
            if (_captureResult != null) _captureResultCard(_captureResult!),
            if (_reconstructionResult != null)
              _reconstructionResultCard(_reconstructionResult!),
            if (_errorMessage != null) _errorCard(_errorMessage!),
          ],
        ),
      ),
    );
  }

  Widget _eventCard(CaptureEvent event) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.bolt),
        title: Text('Last event: ${event.state.name}'),
        subtitle: Text([
          if (event.progress != null)
            'Progress: ${(event.progress! * 100).toStringAsFixed(1)}%',
          if (event.message != null) event.message!,
          if (event.error != null) 'Error: ${event.error}',
        ].join('\n')),
      ),
    );
  }

  Widget _captureResultCard(ObjectCaptureResult result) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder),
        title: const Text('Capture complete'),
        subtitle: Text('${result.captureCount} photos in '
            '${result.duration.inSeconds}s\n${result.imagesFolderPath}'),
      ),
    );
  }

  Widget _reconstructionResultCard(PhotogrammetryResult result) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.view_in_ar),
        title: const Text('Reconstruction complete'),
        subtitle: Text('${result.detailLevel.name} • '
            '${result.processingTime.inSeconds}s\n${result.modelPath}'),
      ),
    );
  }

  Widget _errorCard(String message) {
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
