import UIKit
import VisionKit

@MainActor
public struct LiveTextBox: Equatable {
    public init(frame: CGRect, viewFrame: CGRect, image: UIImage) {
        self.frameWithinView = frame
        self.viewFrame = viewFrame
        
        let imageRatio = image.size.width / image.size.height
        let viewFrameRatio = viewFrame.width / viewFrame.height
        let scaleFactor = image.size.width / viewFrame.size.width
        var scaledRect = frameWithinView
        scaledRect.origin.x *= scaleFactor
        scaledRect.origin.y *= scaleFactor
        if imageRatio > viewFrameRatio {
            scaledRect.origin.y -= (viewFrame.height * scaleFactor - image.size.height) / 2
        } else {
            // TODO: horizontal barndoor correction still buggy
            scaledRect.origin.x -= (viewFrame.width * scaleFactor - image.size.width) / 2
        }
        scaledRect.size.width *= scaleFactor
        scaledRect.size.height *= scaleFactor
        if let croppedCGImage = image.cgImage?.cropping(to: scaledRect) {
            self.image = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        }
    }
    
    var text: String?
    var interaction: ImageAnalysisInteraction?
    var frameWithinView: CGRect
    var viewFrame: CGRect
    var image: UIImage?
    
    var shrunkenFrame: CGRect {
        // TODO: Shrink frame by x% so we can isolate just the text and preserve most for the speech bubble
        // In case we want to remove and overdraw.
        return frameWithinView
    }
    
    mutating func analyse() async {
        if let image = self.image {
            let configuration = ImageAnalyzer.Configuration([.text])
            do {
                let interaction = ImageAnalysisInteraction()
                let analyzer = ImageAnalyzer()
                
                let analysis = try await analyzer.analyze(image, configuration: configuration)
                interaction.analysis = analysis
                interaction.preferredInteractionTypes = .textSelection
                self.interaction = interaction
                self.text = analysis.transcript
            }
            catch {
                print(error)
            }
        }
    }
}

extension Array<LiveTextBox> {
    public func boxContainingPoint(_ point: CGPoint) -> LiveTextBox? {
        for box in self {
            if box.frameWithinView.contains(point) {
                return box
            }
        }
        return nil
    }
    
    public func contains(_ point: CGPoint) -> Bool {
        return boxContainingPoint(point) != nil
    }
}
