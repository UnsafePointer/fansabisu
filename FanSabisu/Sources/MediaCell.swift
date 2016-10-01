import UIKit
import Photos

class MediaCell: UICollectionViewCell {

    var imageView: UIImageView?
    var imageRequestID: PHImageRequestID?

    var asset: PHAsset? {
        didSet {
            let targetSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.version = .original
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            imageRequestID = manager.requestImage(for: self.asset!, targetSize: targetSize, contentMode: .default, options: options) { (image, info) in
                self.imageView?.image = image
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.imageView?.image = nil
        let manager = PHImageManager.default()
        if let imageRequestID = imageRequestID {
            manager.cancelImageRequest(imageRequestID)
        }
    }

}
