import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';

/// View model for `ObjectCapturePage`.
///
/// Owns the calls into `flutter_object_capture` (support probe, guided
/// capture, photogrammetry reconstruction) and the subscription to the
/// plugin's event stream. The view consumes the published state via
/// `provider`.
class ObjectCaptureViewModel extends ChangeNotifier {
  ObjectCaptureViewModel() {
    _checkSupport();
    _eventSubscription = FlutterObjectCapture.events.listen((event) {
      _latestEvent = event;
      notifyListeners();
    });
  }

  StreamSubscription<CaptureEvent>? _eventSubscription;

  bool? _isSupported;
  CaptureEvent? _latestEvent;
  ObjectCaptureResult? _captureResult;
  PhotogrammetryResult? _reconstructionResult;
  String? _errorMessage;
  bool _isBusy = false;

  bool? get isSupported => _isSupported;
  CaptureEvent? get latestEvent => _latestEvent;
  ObjectCaptureResult? get captureResult => _captureResult;
  PhotogrammetryResult? get reconstructionResult => _reconstructionResult;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isBusy;
  bool get canCapture => !_isBusy && (_isSupported ?? false);
  bool get canReconstruct => !_isBusy && _captureResult != null;

  Future<void> _checkSupport() async {
    try {
      _isSupported = await FlutterObjectCapture.isSupported();
    } catch (_) {
      _isSupported = false;
    }
    notifyListeners();
  }

  Future<void> capture() async {
    if (_isBusy) return;
    _isBusy = true;
    _errorMessage = null;
    _captureResult = null;
    _reconstructionResult = null;
    notifyListeners();

    try {
      _captureResult = await FlutterObjectCapture.captureObject();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> reconstruct() async {
    final imagesPath = _captureResult?.imagesFolderPath;
    if (imagesPath == null || _isBusy) return;
    _isBusy = true;
    _errorMessage = null;
    _reconstructionResult = null;
    notifyListeners();

    try {
      _reconstructionResult = await FlutterObjectCapture.reconstruct(
        imagesPath: imagesPath,
        detailLevel: DetailLevel.medium,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
