// Main learning flow action types
enum LearningActionType { display, memory, pair, select, trueFalse, merge }

// Element types used in actions
// visual, audio, target, question

// Display action modes
enum DisplayMode {
  meet, // visual + target + tts
  remember, // visual + target + tts
}

// Memory action types
enum MemoryActionType { visualToTarget, audioToTarget, audioToVisual }

// Pair action types
enum PairActionType { visualToTarget, audioToTarget, audioToVisual }

// Select action types
enum SelectActionType {
  audioToTarget,
  audioToVisual,
  visualToTarget,
  targetToVisual,
  questionToTarget,
}

// True/False action types
enum TrueFalseActionType {
  audioToTarget,
  visualToTarget,
  audioToVisual,
  visualToAudio,
}

// Merge action types
enum MergeActionType { audioToTarget, visualToTarget, questionToTarget }

// Speak action types
enum SpeakActionType { audioToTarget, visualToTarget, questionToTarget }
