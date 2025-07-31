import Observation
import Foundation
import SwiftUI

@Observable
class Model {
    static let shared = Model()
    
    var lastSelectedTextBox: LiveTextBox? {
        didSet {
            lastSelectionDate = .now
        }
    }
    var lastSelectionDate: Date?
    
    var currentImage: UIImage = UIImage(named: "neko-nofurigana")!
    
    public func nextImage() {
        currentImage = UIImage(named: "neko-nofurigana")!
    }
    
    public func prevImage() {
        currentImage = UIImage(named: "0143")!
    }
}
