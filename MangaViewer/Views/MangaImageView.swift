import UIKit
import SwiftUI
import VisionKit

class MangaUIImageView: UIImageView {
    var model = Model.shared

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGesture()
    }
    
    private func setupGesture() {
        if !(gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) ?? false) {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            addGestureRecognizer(tapGesture)
            isUserInteractionEnabled = true
        }
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self)
        model.showToolBar = false
        hitTest(at: point)
    }
    
    public func hitTest(at point: CGPoint) {
        guard let mokuroPage = model.mokuroDocument?.page(forImgPath: model.currentFile) else {
            print("cannot find current page in model")
            return
        }
        
        let blocks = mokuroPage.blockBoundingBoxes
        
        if let imagePixelPoint = convertPointToImagePixelCoords(point) {
            print("Image pixel point: \(String(describing: imagePixelPoint))")
            if let block = blocks.block(containing: imagePixelPoint) {
                let box = MangaBallon(text: block.joinedLines)
                model.lastSelectedTextBox = box
            }
        }
    }
    
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
        track()
    }
        
    func convertPointToImagePixelCoords(_ point: CGPoint) -> CGPoint? {
        guard let image = self.image else { return nil }
        let viewSize = self.bounds.size
        let imageSize = image.size
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        
        // Calculate size of the displayed image
        let displayedImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        // Calculate origin of the image inside the view
        let imageOrigin = CGPoint(x: (viewSize.width - displayedImageSize.width) / 2,
                                 y: (viewSize.height - displayedImageSize.height) / 2)
        // Adjust point to be relative to the image's origin
        let relativePoint = CGPoint(x: point.x - imageOrigin.x, y: point.y - imageOrigin.y)
        // Make sure the point is inside the displayed image
        guard relativePoint.x >= 0, relativePoint.y >= 0,
              relativePoint.x <= displayedImageSize.width, relativePoint.y <= displayedImageSize.height else {
            return nil
        }
        // Scale up to pixel coordinates in the original image
        let imagePixelX = (relativePoint.x / displayedImageSize.width) * imageSize.width
        let imagePixelY = (relativePoint.y / displayedImageSize.height) * imageSize.height
        return CGPoint(x: imagePixelX, y: imagePixelY)
    }
}

@MainActor
struct MangaImageView: UIViewRepresentable {
    let imageView = MangaUIImageView(frame: .zero)
    func makeUIView(context: Context) -> some UIView {
        imageView.contentMode = .scaleAspectFit
        imageView.image = Model.shared.currentImage
        return imageView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}
