import UIKit
import SwiftUI
import VisionKit

class LiveTextImageView: UIImageView, ImageAnalysisInteractionDelegate {
    var liveTextBoxes: [LiveTextBox] = []
    var model = Model.shared
    let analyzer = ImageAnalyzer()
    let interaction = ImageAnalysisInteraction()

    override var image: UIImage? {
        didSet {
            reset()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        .zero
    }
    
    public func track() {
        withObservationTracking {
            let _ = Model.shared.currentImage
        } onChange: {
            Task { @MainActor [weak self] in
                self?.image = Model.shared.currentImage
            }
        }
    }
    
    public func reset() {
        liveTextBoxes.removeAll()
        track()
        addInteraction(interaction)
        Task {
            let configuration = ImageAnalyzer.Configuration([.text])
            do {
                if let image = image {
                    let analysis = try await analyzer.analyze(image, configuration: configuration)
                    interaction.analysis = analysis
                    interaction.preferredInteractionTypes = .textSelection
                    interaction.delegate = self
                    interaction.isSupplementaryInterfaceHidden = true
                    print("segmentation ready")
                }
            }
            catch {
                print(error)
            }
        }

    }
        
    func interaction(_ interaction: ImageAnalysisInteraction, shouldBeginAt point: CGPoint, for interactionType: ImageAnalysisInteraction.InteractionTypes) -> Bool {
        guard !liveTextBoxes.contains(point) else {
            if let speechBubble = liveTextBoxes.boxContainingPoint(point) {
                Model.shared.lastSelectedTextBox = speechBubble
            }
            return true
        }
        let rect = rectangleForInteraction(interaction: interaction, at: point)!
        guard let image = image else { return true }
        var speechBubble = LiveTextBox(frame: rect, viewFrame: frame, image: image)

        Task { [weak self] in
            await speechBubble.analyse()
            self?.liveTextBoxes.append(speechBubble)
            Model.shared.lastSelectedTextBox = speechBubble
        }
        
        let debug = false
        if debug {
            let view = UIView(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor.red.cgColor
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
            addSubview(view)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: topAnchor, constant: rect.origin.y),
                view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: rect.origin.x),
                view.heightAnchor.constraint(equalToConstant: rect.height),
                view.widthAnchor.constraint(equalToConstant: rect.width),
            ])
        }
        
        return true
    }
    
    func rectangleForInteraction(interaction: ImageAnalysisInteraction,
                                 at point: CGPoint) -> CGRect? {
        var visited = Set<[Int]>()
        
        func bfs(startX: Int, startY: Int) -> (region: Set<[Int]>, bounds: CGRect) {
            var queue = [[startX, startY]]
            var region = Set<[Int]>()
            visited.insert([startX, startY])
            
            var minX = startX, maxX = startX
            var minY = startY, maxY = startY
            
            while !queue.isEmpty {
                let (x, y) = (queue[0][0], queue[0][1])
                queue.removeFirst()
                region.insert([x, y])
                
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
                
                let directions = [[0, 1], [1, 0], [0, -1], [-1, 0]]
                for dir in directions {
                    let nx = x + dir[0]
                    let ny = y + dir[1]
                    let point = [nx, ny]
                    
                    if nx >= 0 && ny >= 0 && nx < Int(bounds.width) && ny < Int(bounds.height) &&
                        !visited.contains(point) &&
                        interaction.analysisHasText(at: CGPoint(x: nx, y: ny)) {
                        
                        queue.append(point)
                        visited.insert(point)
                    }
                }
            }
            
            return (
                region,
                CGRect(
                    x: minX,
                    y: minY,
                    width: maxX - minX,
                    height: maxY - minY
                )
            )
        }
        
        let (region, boundingBox) = bfs(startX: Int(point.x), startY: Int(point.y))
        
        if region.count > 0 {
            return boundingBox
        }
        
        return nil
    }
}

@MainActor
struct LiveTextMangaView: UIViewRepresentable {
    let imageView = LiveTextImageView()
    func makeUIView(context: Context) -> some UIView {
        imageView.contentMode = .scaleAspectFit
        imageView.image = Model.shared.currentImage
        return imageView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}
