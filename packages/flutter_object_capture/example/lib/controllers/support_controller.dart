import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import '../helpers/error_message_helper.dart';
import '../models/support_info.dart';

class SupportController extends ChangeNotifier {
  bool _isLoading = false;
  bool _disposed = false;
  SupportInfo? _info;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  SupportInfo? get info => _info;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _info = null;
    _errorMessage = null;
    notifyListeners();
    final processor = ObjectCaptureProcessor();
    try {
      final supported = await ObjectCaptureProcessor.isSupported();
      final limits = supported ? await processor.getLimits() : null;
      _info = SupportInfo(supported: supported, limits: limits);
    } on ObjectCaptureException catch (error) {
      log('support check failed: $error', name: 'SupportController');
      _errorMessage = ErrorMessageHelper.describe(error);
    } finally {
      processor.dispose();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
