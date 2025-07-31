import Foundation
import CoreGraphics

struct MokuroDocument: Decodable, Equatable, Identifiable {
    static func == (lhs: MokuroDocument, rhs: MokuroDocument) -> Bool {
        lhs.titleUUID == rhs.titleUUID && lhs.volumeUUID == rhs .volumeUUID
    }
    
    var id: String {
        "\(volumeUUID)\(titleUUID)"
    }
    
    let version: String
    let title: String
    let titleUUID: String
    let volume: String
    let volumeUUID: String
    let pages: [MokuroPage]
    
    /// Returns the pages sorted by their imgPath in ascending order.
    var pagesSortedByImgPath: [MokuroPage] {
        pages.sorted { $0.imgPath < $1.imgPath }
    }
    
    /// Returns the previous page in the sorted order given an imgPath, or nil if not found or first.
    func previousPage(forImgPath imgPath: String) -> MokuroPage? {
        guard let index = pagesSortedByImgPath.firstIndex(where: { $0.imgPath.contains(imgPath) }), index > 0 else {
            return nil
        }
        return pagesSortedByImgPath[index - 1]
    }

    /// Returns the next page in the sorted order given an imgPath, or nil if not found or last.
    func nextPage(forImgPath imgPath: String) -> MokuroPage? {
        guard let index = pagesSortedByImgPath.firstIndex(where: { $0.imgPath.contains(imgPath) }), index < pagesSortedByImgPath.count - 1 else {
            return nil
        }
        return pagesSortedByImgPath[index + 1]
    }
    
    enum CodingKeys: String, CodingKey {
        case version
        case title
        case titleUUID = "title_uuid"
        case volume
        case volumeUUID = "volume_uuid"
        case pages
    }
    
    enum DynamicPagesCodingKeys: CodingKey {
        case pages
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        title = try container.decode(String.self, forKey: .title)
        titleUUID = try container.decode(String.self, forKey: .titleUUID)
        volume = try container.decode(String.self, forKey: .volume)
        volumeUUID = try container.decode(String.self, forKey: .volumeUUID)
        if let pagesArray = try? container.decode([MokuroPage].self, forKey: .pages) {
            pages = pagesArray
        } else if let pagesDict = try? container.decode([String: MokuroPage].self, forKey: .pages) {
            pages = Array(pagesDict.values)
        } else if let singlePage = try? container.decode(MokuroPage.self, forKey: .pages) {
            pages = [singlePage]
        } else {
            throw DecodingError.dataCorruptedError(forKey: .pages, in: container, debugDescription: "Pages field is not a supported format")
        }
    }
    
    init(path: String) throws {
        let url = URL(fileURLWithPath: path)
        try self.init(url: url)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        let document = try JSONDecoder().decode(MokuroDocument.self, from: data)
        self = document
    }
    
    init(resource: String, withExtension ext: String = "mokuro", bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: resource, withExtension: ext) else {
            throw NSError(domain: "MokuroDocument", code: 404, userInfo: [NSLocalizedDescriptionKey: "Resource not found in bundle"])
        }
        try self.init(url: url)
    }
    
    func page(forImgPath imgPath: String) -> MokuroPage? {
        return pages.first { $0.imgPath.contains(imgPath) }
    }
}

struct MokuroPage: Decodable {
    let version: String
    let imgWidth: Int
    let imgHeight: Int
    let blocks: [MokuroBlock]
    let imgPath: String
    
    enum CodingKeys: String, CodingKey {
        case version
        case imgWidth = "img_width"
        case imgHeight = "img_height"
        case blocks
        case imgPath = "img_path"
    }
    
    var blockBoundingBoxes: [MokuroBlock: CGRect] {
        Dictionary(uniqueKeysWithValues: blocks.compactMap { block in
            guard let bbox = block.boundingBox else { return nil }
            return (block, bbox)
        })
    }
}

struct MokuroBlock: Decodable, Hashable {
    let box: [Double]
    let vertical: Bool
    let fontSize: Double
    let linesCoords: [[[Double]]]
    let lines: [String]
    
    enum CodingKeys: String, CodingKey {
        case box
        case vertical
        case fontSize = "font_size"
        case linesCoords = "lines_coords"
        case lines
    }
    
    var boxesAsCGRect: [CGRect] {
        guard box.count == 4 else { return [] }
        let x1 = box[0]
        let y1 = box[1]
        let x2 = box[2]
        let y2 = box[3]
        let rect = CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
        return [rect]
    }
    
    var boundingBox: CGRect? {
        guard let first = boxesAsCGRect.first else { return nil }
        return boxesAsCGRect.dropFirst().reduce(first) { $0.union($1) }
    }
    
    var joinedLines: String {
        lines.joined()
    }
}

extension Dictionary where Key == MokuroBlock, Value == CGRect {
    /// Returns the MokuroBlock whose bounding box contains the given point, or nil if none.
    func block(containing point: CGPoint) -> MokuroBlock? {
        for (block, rect) in self {
            if rect.contains(point) {
                return block
            }
        }
        return nil
    }
}
