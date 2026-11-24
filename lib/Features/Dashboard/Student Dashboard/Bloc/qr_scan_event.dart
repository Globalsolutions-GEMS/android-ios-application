sealed class QrScanEvent {
  const QrScanEvent();
}

/// A QR code was read by the camera.
class QrScanSubmitted extends QrScanEvent {
  const QrScanSubmitted(this.rawValue);

  final String rawValue;
}

/// Back to scanning after an error.
class QrScanReset extends QrScanEvent {
  const QrScanReset();
}