import SwiftUI
import Mecab_Swift
import Dictionary
import IPADic
import AVFoundation

public struct JapaneseText {
    
    public struct Element: Hashable, Identifiable {
        public var id: String {
            text
        }
        
        public init(mecabAnnotation: Mecab_Swift.Annotation) {
            text = mecabAnnotation.base
            partOfSpeech = mecabAnnotation.partOfSpeech
            transliteration = mecabAnnotation.reading
            dictionaryForm = mecabAnnotation.dictionaryForm
        }

        public var hasFurigana: Bool {
            guard text != transliteration, !text.isKatakana, !text.isHiragana else { return false }
            return true
        }
        
        public let text: String
        public let transliteration: String
        public var translation: String? {
            guard let result = dictionaryLookup else { return nil }
            let regex = try! NSRegularExpression(pattern: "\\(\\d+\\)", options: NSRegularExpression.Options.caseInsensitive)
            return regex.stringByReplacingMatches(in: result.translation, options: [], range: NSMakeRange(0, result.translation.count), withTemplate: "\n • ")
        }
        public let dictionaryForm: String
        public let partOfSpeech: PartOfSpeech
        
        public var dictionaryLookup: Result? {
            let wordToLookUp = text.isKatakana ? text : dictionaryForm
            let (results, _) = Dict.shared.search(wordToLookUp, limit: 10)
            guard results.count > 0 else { return nil }
            for result in results {
                if result.kana == transliteration {
                    return result
                }
            }
            guard let result = results.first else { return nil }
            return result
        }
        
        public var openInNihongoURL: URL {
            return URL(string: String(format: "nihongo://search/%@", dictionaryForm))!
        }
        
        public var color: Color {
            Color(uiColor: uiColor)
        }

        public var uiColor: UIColor {
            switch partOfSpeech {
            case .noun:
                return UIColor(named: "noun")!
            case .verb:
                return UIColor(named: "verb")!
            case .particle:
                return UIColor(named: "particle")!
            case .adverb:
                return UIColor(named: "adverb")!
            case .adjective:
                return UIColor(named: "adjective")!
            case .prefix:
                return UIColor(named: "prefix")!
            default:
                return UIColor(named: "regular")!
            }
        }

        func speak() {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
            utterance.rate = 0.2
            AVSpeechSynthesizer().speak(utterance)
        }
    }
    
    public init(_ japaneseText: String) {
        do {
            let tokenizer = try Tokenizer(dictionary: IPADic())
            let annotations = tokenizer.tokenize(text: japaneseText)
            elements = annotations.map { JapaneseText.Element(mecabAnnotation: $0) }
        } catch {
            elements = []
        }
    }

    var elements: [JapaneseText.Element] = []
}

public extension String {
    var isKatakana: Bool {
        let katakanaRange = 0x30A0...0x30FF
        for scalar in self.unicodeScalars {
            if !katakanaRange.contains(Int(scalar.value))  { return false }
        }
        return true
    }
    
    var isHiragana: Bool {
        let hiraganaRange = 0x3040...0x309F
        for scalar in self.unicodeScalars {
            if !hiraganaRange.contains(Int(scalar.value))  { return false }
        }
        return true
    }
}
