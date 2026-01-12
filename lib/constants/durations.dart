class Durations {
  // Standard delays
  static const Duration ttsDelay = Duration(milliseconds: 350);
  static const Duration initialDelay = Duration(milliseconds: 350);
  static const Duration postTtsDelay = Duration(milliseconds: 350);
  static const Duration fadeOutDelay = Duration(milliseconds: 350);

  // Card delays
  static const Duration cardDelay = Duration(seconds: 1);
  static const Duration visualComprehensionDelay = Duration(seconds: 1);

  // Animation durations
  static const Duration fadeAnimation = Duration(milliseconds: 300);

  // Feedback durations
  static const Duration feedbackDisplay = Duration(seconds: 1);
  static const Duration wrongChunkFeedback = Duration(milliseconds: 800);

  // Private constructor to prevent instantiation
  Durations._();
}
