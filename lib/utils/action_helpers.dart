import 'package:lingos/constants/durations.dart' as AppDurations;

/// Helper class for common action flow operations
class ActionHelpers {
  /// Calculate wait duration based on text length
  /// Returns a duration that allows reading time (roughly 50ms per character)
  static Duration calculateTextWaitDuration(String? text) {
    if (text == null || text.isEmpty) {
      return AppDurations.Durations.ttsDelay;
    }
    final length = text.length;
    return Duration(
      milliseconds:
          (AppDurations.Durations.ttsDelay.inMilliseconds + (length * 50))
              .clamp(AppDurations.Durations.ttsDelay.inMilliseconds, 2000),
    );
  }

  /// Check if widget is still mounted and flow hasn't changed
  static bool shouldContinue(bool mounted, int currentFlow, int flowId) {
    return mounted && currentFlow == flowId;
  }
}
