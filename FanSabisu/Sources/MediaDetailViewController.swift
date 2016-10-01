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
        options.isNetworkAccessAllowed = true
        manager.requestImageData(for: asset!, options: options) { (data, dataUTI, orientation, info) in
            if let data = data {
                self.imageView?.image = UIImage.animatedImage(with: data)
            }
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
            self.delete()
        }))
        controller.addAction(UIAlertAction(title: String.localizedString(for: "CANCEL"), style: .cancel, handler: { (action) in
        }))
        controller.addAction(UIAlertAction(title: String.localizedString(for: "INFORMATION"), style: .default, handler: { (action) in
            self.displayInformation()
        }))
        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.popoverPresentationController?.barButtonItem = sender
        }
        present(controller, animated: true, completion: nil)
    }

    func delete() {
        PHPhotoLibrary.shared().performChanges({
            let array = NSArray(object: self.asset!)
            PHAssetChangeRequest.deleteAssets(array)
        }) { (success, error) in
            if let _ = error {
                DispatchQueue.main.async {
                    self.presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "DELETE_ERROR"), actionHandler: nil)
                }
            } else if success {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "UnwindToMedia", sender: nil)
                }
            }
        }
    }

}
