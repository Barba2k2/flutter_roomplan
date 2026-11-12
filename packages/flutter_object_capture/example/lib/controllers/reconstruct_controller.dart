import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter_object_capture/flutter_object_capture.dart';
import '../helpers/documents_path_helper.dart';
import '../helpers/error_message_helper.dart';
import '../helpers/supported_details_helper.dart';
import '../models/reconstruct_form.dart';
import '../models/reconstruct_phase.dart';
import '../models/result_info.dart';
import '../strings/app_strings.dart';

class ReconstructController extends ChangeNotifier {
  ReconstructController({
    ObjectCaptureProcessor? processor,
    Future<String> Function()? documentsPath,
    Future<bool> Function()? guidedCaptureSupported,
    Future<void> Function(String path)? createDirectory,
    List<ObjectDetail>? supportedDetails,
  })  : _processor = processor ?? ObjectCaptureProcessor(),
        _documentsPath = documentsPath ?? DocumentsPathHelper.path,
        _guidedCaptureSupported = guidedCaptureSupported ??
            ObjectCaptureProcessor.isGuidedCaptureSupported,
        _createDirectory = createDirectory ?? _createOnDisk,
        _supportedDetails =
            supportedDetails ?? SupportedDetailsHelper.forCurrentPlatform();

  static const _extension = '.usdz';

  final ObjectCaptureProcessor _processor;
  final Future<String> Function() _documentsPath;
  final Future<bool> Function() _guidedCaptureSupported;
  final Future<void> Function(String path) _createDirectory;
  final List<ObjectDetail> _supportedDetails;

  static Future<void> _createOnDisk(String path) async {
    await Directory(path).create(recursive: true);
  }

  ReconstructForm _form = const ReconstructForm();
  ReconstructPhase _phase = ReconstructPhase.idle;
  double _progress = 0;
  Duration? _remaining;
  List<ReconstructionEvent> _events = const [];
  String? _errorMessage;
  ResultInfo? _result;
  bool _isCapturing = false;
  bool _isGuidedCaptureAvailable = true;
  bool _disposed = false;

  ReconstructForm get form => _form;
  ReconstructPhase get phase => _phase;
  bool get isRunning => _phase == ReconstructPhase.running;
  double get progress => _progress;
  Duration? get remaining => _remaining;
  List<ReconstructionEvent> get events => _events;
  String? get errorMessage => _errorMessage;
  ResultInfo? get result => _result;
  bool get isCapturing => _isCapturing;
  List<ObjectDetail> get supportedDetails => _supportedDetails;

  /// The detail selector is pointless with a single level (iOS).
  bool get showDetailSelector => _supportedDetails.length > 1;

  /// False once the device is known to lack guided capture; hides the button.
  bool get isGuidedCaptureAvailable => _isGuidedCaptureAvailable;
  bool get isBusy => isRunning || _isCapturing;

  void setImagesDirectory(String path) {
    _form = _form.copyWith(imagesDirectory: path);
    _errorMessage = null;
    notifyListeners();
  }

  void setOutputName(String name) {
    _form = _form.copyWith(outputName: name);
  }

  /// Ignores a level the platform does not support.
  void setDetail(ObjectDetail detail) {
    if (!_supportedDetails.contains(detail)) return;
    _form = _form.copyWith(detail: detail);
    notifyListeners();
  }

  Future<void> loadCapabilities() async {
    _isGuidedCaptureAvailable = await _guidedCaptureSupported();
    notifyListeners();
  }

  /// Opens guided capture into a fresh, empty folder and, on success, uses
  /// that folder as the photos folder. Does nothing while busy.
  Future<void> capturePhotos() async {
    if (isBusy) return;
    _isCapturing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (!await _guidedCaptureSupported()) {
        _errorMessage = AppStrings.guidedUnsupported;
        return;
      }
      final folder = await _documentsPath();
      final imagesDirectory =
          '$folder/captures/capture-${DateTime.now().millisecondsSinceEpoch}';
      await _createDirectory(imagesDirectory);
      final captured = await _processor.captureImages(
        imagesDirectory: imagesDirectory,
      );
      _form = _form.copyWith(imagesDirectory: captured.imagesDirectory);
    } catch (error) {
      log('capture failed: $error', name: 'ReconstructController');
      _errorMessage = error is ReconstructionCancelledException
          ? AppStrings.captureCancelled
          : ErrorMessageHelper.describe(error);
    } finally {
      _isCapturing = false;
      notifyListeners();
    }
  }

  /// Runs one reconstruction. Does nothing while one is already running.
  Future<void> start() async {
    if (isBusy) return;
    final directory = _form.imagesDirectory;
    final name = _form.outputName.trim();
    final problem = _validate(directory, name);
    if (problem != null) {
      _phase = ReconstructPhase.failed;
      _errorMessage = problem;
      notifyListeners();
      return;
    }
    _phase = ReconstructPhase.running;
    _progress = 0;
    _remaining = null;
    _events = const [];
    _errorMessage = null;
    _result = null;
    notifyListeners();
    try {
      final folder = await _documentsPath();
      final fileName = name.endsWith(_extension) ? name : '$name$_extension';
      final stream = _processor.reconstruct(
        imagesDirectory: directory!,
        outputPath: '$folder/$fileName',
        configuration: ObjectCaptureConfiguration(detail: _form.detail),
      );
      await for (final event in stream) {
        _onEvent(event);
      }
      if (isRunning) {
        _finish(ReconstructPhase.failed, AppStrings.errorUnexpectedEnd);
      }
    } catch (error) {
      log('reconstruction failed: $error', name: 'ReconstructController');
      _finish(
        error is ReconstructionCancelledException
            ? ReconstructPhase.cancelled
            : ReconstructPhase.failed,
        ErrorMessageHelper.describe(error),
      );
    }
  }

  /// Asks the device to stop. Does nothing when nothing is running.
  Future<void> cancel() async {
    if (!isRunning) return;
    try {
      await _processor.cancel();
    } on ObjectCaptureException catch (error) {
      log('cancel failed: $error', name: 'ReconstructController');
      _finish(ReconstructPhase.failed, ErrorMessageHelper.describe(error));
    }
  }

  String? _validate(String? directory, String name) {
    if (directory == null || directory.trim().isEmpty) {
      return AppStrings.errorNoFolder;
    }
    if (name.isEmpty) return AppStrings.errorNoName;
    if (name.contains('/')) return AppStrings.errorBadName;
    return null;
  }

  void _onEvent(ReconstructionEvent event) {
    switch (event) {
      case ReconstructionProgress(:final fraction, :final estimatedRemaining):
        _progress = fraction;
        _remaining = estimatedRemaining;
      case ReconstructionSampleIssue() || ReconstructionNotice():
        _events = [..._events, event];
      case ReconstructionCompleted(:final modelPath, :final fileSizeBytes):
        _progress = 1;
        _remaining = null;
        _result = ResultInfo(path: modelPath, fileSizeBytes: fileSizeBytes);
        _phase = ReconstructPhase.completed;
    }
    notifyListeners();
  }

  void _finish(ReconstructPhase phase, String message) {
    _phase = phase;
    _errorMessage = message;
    _remaining = null;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _processor.dispose();
    super.dispose();
  }
}
