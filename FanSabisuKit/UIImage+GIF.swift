import Foundation
import ImageIO

extension UIImage {

    public class func animatedImage(with data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        let count = CGImageSourceGetCount(source)

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

        var frames = [UIImage]()
        for index in 0..<count {
            let frame = UIImage(cgImage: images[index])
            let frameCount = Int(delays[index] / gcdResult)
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        return UIImage.animatedImage(with: frames, duration: Double(duration) / 1000)
    }

    class func delay(at index: Int, from source: CGImageSource) -> Double {
        let defaultDelay = 0.1
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? Dictionary<String, Any>
        let GIFProperties = properties?[kCGImagePropertyGIFDictionary as String] as? Dictionary<String, Any>
        if let delay: Double = GIFProperties?[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
            if delay != 0 {
                return delay
            }
        }
        if let delay: Double = GIFProperties?[kCGImagePropertyGIFDelayTime as String] as? Double {
            if delay != 0 {
                return delay
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
