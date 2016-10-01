import UIKit
import Foundation
import Photos
import FanSabisuKit

class MediaDetailViewController: UIViewController {

    var asset: PHAsset?
    @IBOutlet var imageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localizedString(for: "DETAILS")
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = false
        manager.requestImageData(for: asset!, options: options) { (data, dataUTI, orientation, info) in
            self.imageView?.image = UIImage.animatedImage(with: data!)
        }

    }

    func displayInformation() {
        let manager = PHImageManager.default()
        manager.requestImageData(for: asset!, options: nil) { (data, dataUTI, orientation, info) in
            let size = ByteCountFormatter.string(fromByteCount: Int64(data!.count), countStyle: .file)
            let message = String(format: String.localizedString(for: "FILE_SIZE"), size)
            let controller = UIAlertController(title: String.localizedString(for: "INFORMATION"), message: message, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: String.localizedString(for: "DISMISS"), style: .default, handler: nil))
            self.present(controller, animated: true, completion: nil)
        }
    }

    @IBAction func action(sender: UIBarButtonItem) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: String.localizedString(for: "DELETE"), style: .destructive, handler: { (action) in
        }))
        controller.addAction(UIAlertAction(title: String.localizedString(for: "CANCEL"), style: .cancel, handler: { (action) in
        }))
        controller.addAction(UIAlertAction(title: String.localizedString(for: "INFORMATION"), style: .default, handler: { (action) in
            self.displayInformation()
        }))
        present(controller, animated: true, completion: nil)
    }

}
