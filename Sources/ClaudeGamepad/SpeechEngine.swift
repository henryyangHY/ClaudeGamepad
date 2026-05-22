import Foundation

/// No-op stub.
///
/// The original implementation used SFSpeechRecognizer (Speech.framework), but
/// linking that framework into a non-bundled binary crashes on macOS 26 at
/// launch — TCC enforces NSSpeechRecognitionUsageDescription via the Info.plist,
/// and an unbundled executable has no Info.plist.
///
/// Voice input through this engine is disabled. Users can route a gamepad
/// button to an external voice tool (e.g., Typeless) via the Combo action.
final class SpeechEngine {
    static let shared = SpeechEngine()

    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onAudioLevel: ((Float) -> Void)?

    private init() {}

    func startListening() {
        onError?("System speech recognition is disabled in this build. Use Whisper or an external voice tool.")
    }

    func stopListening() {}
}
