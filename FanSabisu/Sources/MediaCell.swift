import UIKit
import Photos

class MediaCell: UICollectionViewCell {

    var imageView: UIImageView?

    var asset: PHAsset? {
        didSet {
            let manager = PHImageManager.default()
            manager.requestImage(for: self.asset!, targetSize: self.frame.size, contentMode: .aspectFill, options: nil) { (image, info) in
                self.imageView?.image = image
            }
        }
    }

}
