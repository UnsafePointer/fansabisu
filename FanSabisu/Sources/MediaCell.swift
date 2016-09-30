import UIKit
import Photos

class MediaCell: UICollectionViewCell {

    var imageView: UIImageView?

    var asset: PHAsset? {
        didSet {
            let targetSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.version = .original
            options.isSynchronous = false
            manager.requestImage(for: self.asset!, targetSize: targetSize, contentMode: .default, options: options) { (image, info) in
                self.imageView?.image = image
            }
        }
    }

}
