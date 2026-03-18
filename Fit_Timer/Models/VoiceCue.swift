import Foundation
import AVFoundation
import UIKit

/// 짧은 음성 안내/삑음/햅틱을 내보내는 공용 유틸
final class VoiceCue {
    static let shared = VoiceCue()

    private let speaker = AVSpeechSynthesizer()
    private let session = AVAudioSession.sharedInstance()

    private init() {
        // 무음 스위치(사일런트)여도 들리도록 .playback (필요 없으면 .ambient 로)
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: [])
    }

    /// 한국어 기본 TTS
    func speak(_ text: String, lang: String = "ko-KR", rate: Float = 0.48) {
        // 같은 문구가 겹쳐 줄 서지 않게 즉시 중단 후 재생
        if speaker.isSpeaking { speaker.stopSpeaking(at: .immediate) }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: lang)
        u.rate = rate
        speaker.speak(u)
    }

    /// 짧은 확인 햅틱
    func successHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// 가벼운 탭 햅틱
    func tapHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
