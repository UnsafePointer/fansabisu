import UIKit
import Foundation
import Photos

class MediaDetailViewController: UIViewController {

    var asset: PHAsset?
    @IBOutlet var imageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()

        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = false
        manager.requestImage(for: asset!, targetSize: imageView!.frame.size, contentMode: .default, options: options) { (image, info) in
            self.imageView?.image = image
        }

    }

    func displayInformation() {
        let manager = PHImageManager.default()
        manager.requestImageData(for: asset!, options: nil) { (data, dataUTI, orientation, info) in
            let size = ByteCountFormatter.string(fromByteCount: Int64(data!.count), countStyle: .file)
            let message = "File size: \(size)"
            let controller = UIAlertController(title: "Information", message: message, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(controller, animated: true, completion: nil)
        }
    }

    @IBAction func action(sender: UIBarButtonItem) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
        }))
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
        }))
        controller.addAction(UIAlertAction(title: "Information", style: .default, handler: { (action) in
            self.displayInformation()
        }))
        present(controller, animated: true, completion: nil)
    }

}
