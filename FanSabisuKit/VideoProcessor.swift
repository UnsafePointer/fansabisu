import Foundation
import AVFoundation
import ImageIO
import MobileCoreServices
import Photos

enum VideoProcessorError: Error {
    case InvalidDestination
    case ProcessingFailed
}

public class VideoProcessor {
    
    public init() {
    }
    
    public func processVideo(with fileURL: URL, completionHandler: @escaping (Result<URL>) -> Void) {
        DispatchQueue.global().async {
            let userDefaults = UserDefaults(suiteName: "group.com.ruenzuo.FanSabisu")!
            var fps = userDefaults.double(forKey: SettingKey.fps.rawValue)
            if fps == 0 {
                fps = 24
            }
            let asset = AVAsset(url: fileURL)
            let videoLength = CMTimeGetSeconds(asset.duration)
            print(String(format: "Video length (value): %.2f", videoLength))
            let requiredFrames = Int64(videoLength * fps)
            print(String(format: "Required frames: %d", requiredFrames))
            let step = asset.duration.value / requiredFrames
            print(String(format: "Step: %d", step))
            var currentTime: Int64 = 0
            var frames = [UIImage]()
            for _ in 1...requiredFrames {
                let generator = AVAssetImageGenerator(asset: asset)
                generator.requestedTimeToleranceAfter = kCMTimeZero
                generator.requestedTimeToleranceBefore = kCMTimeZero
                generator.appliesPreferredTrackTransform = true

                let time = CMTimeMake(currentTime, asset.duration.timescale)
                if let imageRef = try? generator.copyCGImage(at: time, actualTime: nil) {
                    let image = UIImage(cgImage: imageRef)
                    frames.append(image)
                }

                currentTime += step
            }

            let temporaryDirectoryFilePath = URL(fileURLWithPath: NSTemporaryDirectory())
            let temporaryURL = temporaryDirectoryFilePath.appendingPathComponent(fileURL.lastPathComponent.replacingOccurrences(of: ".mp4", with: ".gif"))

            let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]]
            let gifProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: CMTimeGetSeconds(asset.duration) / Double(requiredFrames)]]
            guard let destination = CGImageDestinationCreateWithURL(temporaryURL as CFURL, kUTTypeGIF, Int(requiredFrames), nil) else {
                return DispatchQueue.main.async { completionHandler(Result.Failure(VideoProcessorError.InvalidDestination)) }
            }
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
            for frame in frames {
                if let cgImage = frame.cgImage {
                    CGImageDestinationAddImage(destination, cgImage, gifProperties  as CFDictionary)
                }
            }

            if (!CGImageDestinationFinalize(destination)) {
                return DispatchQueue.main.async { completionHandler(Result.Failure(VideoProcessorError.ProcessingFailed)) }
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: temporaryURL)
            }) { (success, error) in
                let result: Result<URL>
                if let error = error {
                    result = Result.Failure(error)
                } else {
                    result = Result.Success(temporaryURL)
                }
                DispatchQueue.main.async { completionHandler(result) }
            }
        }
    }
    
}
