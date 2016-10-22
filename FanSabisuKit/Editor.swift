import Foundation
import ImageIO
import AVFoundation
import MobileCoreServices

public enum Edit {
    case speedup
    case slowdown
}

public class Editor {

    let edit: Edit
    let data: Data

    public init(data: Data, edit: Edit) {
        self.edit = edit
        self.data = data
    }

    public func apply() -> URL? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        let count = CGImageSourceGetCount(source)
        var frames = [CGImage]()
        var delays = [Double]()
        for index in 0..<count {
            guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }
            frames.append(frame)
            let delay = UIImage.delay(at: index, from: source)
            delays.append(delay)
        }
        let duration = delays.reduce(0, +)
        let actualDelayPerFrame = duration / Double(frames.count)

        let temporaryDirectoryFilePath = URL(fileURLWithPath: NSTemporaryDirectory())
        let temporaryURL = temporaryDirectoryFilePath.appendingPathComponent(UUID().uuidString)

        let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]
        let gifProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: actualDelayPerFrame * self.modifier()]]
        guard let destination = CGImageDestinationCreateWithURL(temporaryURL as CFURL, kUTTypeGIF, frames.count, nil) else {
            return nil
        }
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
        for frame in frames {
            CGImageDestinationAddImage(destination, frame, gifProperties  as CFDictionary)
        }
        if (!CGImageDestinationFinalize(destination)) {
            return nil
        }
        
        return temporaryURL
    }

    func modifier() -> Double {
        switch edit {
        case .speedup:
            return 0.5
        case .slowdown:
            return 2.0
        }
    }

}
