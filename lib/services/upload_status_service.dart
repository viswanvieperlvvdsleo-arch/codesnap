import 'dart:async';

import 'package:flutter/foundation.dart';

enum UploadState { idle, uploading, success, failed, canceled }

/// App-wide upload signal used by the header avatar ring.
class UploadStatusService extends ChangeNotifier {
  UploadStatusService._();

  static final UploadStatusService instance = UploadStatusService._();

  UploadState state = UploadState.idle;
  double progress = 0;
  String label = '';
  Timer? _settleTimer;

  void start({String label = 'Uploading'}) {
    _settleTimer?.cancel();
    state = UploadState.uploading;
    progress = 0.5;
    this.label = label;
    notifyListeners();
  }

  void update(double value) {
    if (state != UploadState.uploading) return;
    progress = value.clamp(0.05, 0.95);
    notifyListeners();
  }

  void succeed({String label = 'Uploaded'}) {
    _settle(UploadState.success, label);
  }

  void fail({String label = 'Upload failed'}) {
    _settle(UploadState.failed, label);
  }

  void cancel({String label = 'Upload canceled'}) {
    _settle(UploadState.canceled, label);
  }

  void _settle(UploadState nextState, String nextLabel) {
    _settleTimer?.cancel();
    state = nextState;
    progress = nextState == UploadState.success ? 1 : 0;
    label = nextLabel;
    notifyListeners();
    _settleTimer = Timer(const Duration(seconds: 3), () {
      state = UploadState.idle;
      progress = 0;
      label = '';
      notifyListeners();
    });
  }
}
