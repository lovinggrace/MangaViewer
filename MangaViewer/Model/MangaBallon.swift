import UIKit
import VisionKit
import AVFoundation

@MainActor
public struct MangaBallon: Equatable {
    var text: String
}

extension String {
    private static let sharedSynth = AVSpeechSynthesizer()
    
    func speakInJapanese() {
        let utterance = AVSpeechUtterance(string: self)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        String.sharedSynth.speak(utterance)
    }
}
