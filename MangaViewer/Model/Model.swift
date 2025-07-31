import Observation
import Foundation
import SwiftUI

@Observable
class Model {
    static let shared = Model()
    var filesInFolder: [URL] = []
    
    func file(matching: String) -> URL? {
        filesInFolder.first(where: {$0.absoluteString.removingPercentEncoding!.contains(matching)})
    }
    
    private func recursiveContentsOfDirectory(at url: URL) -> [URL] {
        var urls: [URL] = []
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if !url.startAccessingSecurityScopedResource() {
                    print("Nope: \(url)")
                } else {
                    urls.append(fileURL)
                }
            }
        }
        return urls
    }
    
    func loadMokuroDocument(folder: URL) {
        _ = folder.startAccessingSecurityScopedResource()
        
        filesInFolder.removeAll()
        filesInFolder = recursiveContentsOfDirectory(at: folder)

        if let url = filesInFolder.first(where: { $0.absoluteString.hasSuffix(".mokuro")}) {
            do {
                let document = try MokuroDocument(url: url)
                self.mokuroDocument = document
                loadFirstImage()
            } catch {
                print("could not load mokuro \(url) \(error)")
            }
        } else {
            print("No mokuro file")
        }

    }
    
    func loadFirstImage() {
        guard let mokuroDocument,
              let firstPage = mokuroDocument.pagesSortedByImgPath.first else { return }
        
        currentImagePath = file(matching: Defaults.lastPage[mokuroDocument.id] ?? firstPage.imgPath)
    }
    
    var lastSelectedTextBox: MangaBallon? {
        didSet {
            lastSelectionDate = .now
        }
    }
    
    var lastSelectionDate: Date?
    var showToolBar: Bool = false
    var showTranslation: Bool = false
    var showTextDrawer: Bool = false

    var currentImagePath: URL? {
        didSet {
            if let currentImagePath {
                self.currentImage = UIImage.loadImage(at: currentImagePath)
            }
        }
    }
    
    var currentFile: String {
        guard let currentImagePath else { return "" }
        let (_, filename, fileExtension) = currentImagePath.absoluteString.removingPercentEncoding!.splitPathComponents
        return "\(filename).\(fileExtension)"
    }
    
    var currentImage: UIImage?
    
    var mokuroDocument: MokuroDocument?
    
    public func nextImage() {
        guard let mokuroDocument, currentImagePath != nil else { return }
        guard let path = mokuroDocument.nextPage(forImgPath: currentFile)?.imgPath else { return }
        self.currentImagePath = file(matching: path)
        Defaults.lastPage[mokuroDocument.id] = currentFile
    }
    
    public func prevImage() {
        guard let mokuroDocument, currentImagePath != nil else { return }
        guard let path = mokuroDocument.previousPage(forImgPath: currentFile)?.imgPath else { return }
        self.currentImagePath = file(matching: path)
        Defaults.lastPage[mokuroDocument.id] = currentFile
    }
    
    func savePage() {
        
    }
}

// Utility to load WebP images from the main bundle
extension UIImage {
    static func findImageInBundle(named name: String, extension: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: `extension`) else {
            return nil
        }
        return loadImage(at: url)
    }
    
    static func loadImage(at url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            print("cannot load \(url)")
            return nil
        }
        return image
    }
}

extension String {
    /// Splits a file path string into (directory, filename, extension)
    var splitPathComponents: (directory: String, filename: String, fileExtension: String) {
        let ns = self as NSString
        let directory = ns.deletingLastPathComponent
        let filename = (ns.deletingPathExtension as NSString).lastPathComponent
        let fileExtension = ns.pathExtension
        return (directory, filename, fileExtension)
    }
}
