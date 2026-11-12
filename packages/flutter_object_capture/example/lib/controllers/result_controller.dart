import 'dart:io';

import 'package:flutter/foundation.dart';
import '../models/result_info.dart';
import '../strings/app_strings.dart';

class ResultController extends ChangeNotifier {
  ResultController(this.info);

  final ResultInfo info;
  bool _fileExists = true;
  String? _errorMessage;
  bool _disposed = false;

  bool get fileExists => _fileExists;
  String? get errorMessage => _errorMessage;

  Future<void> checkFile() async {
    _fileExists = await File(info.path).exists();
    _errorMessage = _fileExists ? null : AppStrings.resultMissing;
    notifyListeners();
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

  void reportShareFailed() {
    _errorMessage = AppStrings.resultShareFailed;
    notifyListeners();
  }
}
