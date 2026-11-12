/// All UI text of the example app.
class AppStrings {
  AppStrings._();

  static const appTitle = 'Object Capture Example';

  // Support page
  static const supportTitle = 'Device support';
  static const supportChecking = 'Checking this device...';
  static const supportedHeadline = 'Object Capture is supported';
  static const unsupportedHeadline = 'Object Capture is not supported';
  static const unsupportedBody =
      'This device cannot reconstruct models. Object Capture needs iOS 17 or '
      'newer on supported hardware (an iPhone or iPad with LiDAR). Running on '
      'the Simulator also ends here.';
  static const deviceNote =
      'Support is decided by the system at runtime. Use photos taken by you '
      'with the Camera app; HEIC photos with depth give the model a real '
      'scale.';
  static const limitsTitle = 'Limits on this device';
  static const limitsMaxImages = 'Maximum number of photos';
  static const limitsMaxDimension = 'Maximum photo size (pixels)';
  static const checkAgain = 'Check again';
  static const continueToReconstruct = 'Continue';

  // Reconstruct page
  static const reconstructTitle = 'Reconstruct a model';
  static const chooseFolder = 'Choose photos folder';
  static const changeFolder = 'Change photos folder';
  static const capturePhotos = 'Capture photos';
  static const guidedUnsupported =
      'Guided capture is not available on this device. It needs iOS 17 or '
      'newer and an iPhone or iPad with LiDAR. Choose a photos folder instead.';
  static const captureCancelled = 'The capture was cancelled.';
  static const detailLabel = 'Model detail';
  static const detailPreview = 'Preview';
  static const detailReduced = 'Reduced';
  static const detailMedium = 'Medium';
  static const detailFull = 'Full';
  static const detailRaw = 'Raw';
  static const noFolderChosen = 'No folder chosen yet.';
  static const outputNameLabel = 'Output file name';
  static const outputNameHint = 'model';
  static const outputNameHelper =
      'Saved in the app documents folder. ".usdz" is added when missing.';
  static const start = 'Start';
  static const cancel = 'Cancel';
  static const progressTitle = 'Progress';
  static const progressPreparing = 'Preparing...';
  static const eventsTitle = 'Photo issues and notices';
  static const eventsEmpty = 'Nothing to report so far.';

  // Result page
  static const resultTitle = 'Result';
  static const resultPath = 'File';
  static const resultSize = 'Size';
  static const resultShare = 'Share or save the USDZ';
  static const resultMissing = 'The file is no longer on the device.';
  static const resultShareFailed = 'Could not open the share sheet.';
  static const resultBack = 'Reconstruct another';

  // Validation messages
  static const errorNoFolder =
      'Choose the folder with your photos before starting.';
  static const errorNoName = 'Type a name for the output file.';
  static const errorBadName =
      'The file name cannot contain a slash. Type only a name.';
  static const errorUnexpectedEnd =
      'The reconstruction ended without a result. Try again.';

  // Exception messages
  static const errorNotSupported =
      'This device does not support Object Capture.';
  static const errorInvalidImages =
      'The photos folder cannot be used. Choose a folder that exists and has '
      'photos in it.';
  static const errorInvalidOutput =
      'The output file cannot be written. Try another file name.';
  static const errorUnsupportedDetail =
      'This detail level is not supported on this device. Choose another one.';
  static const errorStorage = 'Not enough free storage on this device.';
  static const errorInProgress = 'A reconstruction is already running.';
  static const errorCancelled = 'The reconstruction was cancelled.';
  static const errorFailed = 'The reconstruction failed';
  static const errorNative = 'Unexpected error from the device';
  static const errorPayload = 'The device sent data the app did not expect';
  static const errorDirectoryNotEmpty =
      'The capture folder already has files in it. Try again.';
  static const errorSensor = 'The camera or LiDAR sensor stopped working.';
  static const errorTracking =
      'The camera lost tracking. Move slower and try again.';
  static const errorCapture = 'The capture failed';
  static const errorUnknown = 'Something unexpected happened';

  // Event log
  static const noticeInputComplete = 'All photos were read.';
  static const noticeDownsampling =
      'The system reduced the photo quality to fit in memory.';
  static const noticeStitching =
      'Some photos could not be joined. The model may have holes.';
  static const sampleSkipped = 'Photo skipped';
  static const sampleInvalid = 'Photo rejected';
}
