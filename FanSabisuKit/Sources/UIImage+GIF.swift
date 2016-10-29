import Foundation
import ImageIO

extension UIImage {

    public enum GIFInformationKey: String {
        case frames = "Frames"
        case fps = "FramesPerSecond"
        case duration = "Duration"
        case data = "Data"
    }

    public class func animatedImage(with url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        let result = animatedImage(with: data)
        return result.0
    }

    public class func animatedImage(with data: Data) -> (UIImage?, Dictionary<String, Any>?) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return (nil, nil)
        }
        var information = Dictionary<String, Any>()
        information[GIFInformationKey.data.rawValue] = data

        let count = CGImageSourceGetCount(source)
        information[GIFInformationKey.frames.rawValue] = count

        var images = [CGImage]()
        var delays = [Int]()
        for index in 0..<count {
            guard let image = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }
            images.append(image)
            let delay = self.delay(at: index, from: source)
            delays.append(Int(delay * 1000))
        }

        let duration = delays.reduce(0, +)
        let gcdResult = delays.reduce(0, gcd)

        let durationInSeconds = Double(duration) / 1000
        information[GIFInformationKey.duration.rawValue] = durationInSeconds.roundToPlaces(2)
        information[GIFInformationKey.fps.rawValue] = Int(Double(count) / Double(durationInSeconds))

        var frames = [UIImage]()
        for index in 0..<count {
            let frame = UIImage(cgImage: images[index])
            let frameCount = Int(delays[index] / gcdResult)
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        let animation = UIImage.animatedImage(with: frames, duration: durationInSeconds)
        return (animation, information)
    }

    class func delay(at index: Int, from source: CGImageSource) -> Double {
        let defaultDelay = 0.10
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? Dictionary<String, Any>
        let GIFProperties = properties?[kCGImagePropertyGIFDictionary as String] as? Dictionary<String, Any>
        if let delay: Double = GIFProperties?[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
            if delay != 0 {
                return delay.roundToPlaces(2)
            }
        }
        if let delay: Double = GIFProperties?[kCGImagePropertyGIFDelayTime as String] as? Double {
            if delay != 0 {
                return delay.roundToPlaces(2)
            }
        }
        return defaultDelay
    }

}

private func gcd(_ a: Int, _ b: Int) -> Int {
    let r = a % b
    if r != 0 {
        return gcd(b, r)
    } else {
        return b
    }
}
