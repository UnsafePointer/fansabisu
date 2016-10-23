import UIKit
import FanSabisuKit
import Photos

class PreviewViewController: GAITrackedViewController {

    var url: URL?
    @IBOutlet var imageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localizedString(for: "PREVIEW")
        self.screenName = "Preview"
        if let url = self.url {
            let image = UIImage.animatedImage(with: url)
            self.imageView?.image = image
        }
    }

    @IBAction func save(with sender: UIBarButtonItem) {
        if let url = self.url {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            }) { (success, error) in
                if let _ = error {
                    self.presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "SAVE_FAILED"), actionHandler: nil)
                } else {
                    let manager = FileManager.default
                    try? manager.removeItem(at: url)
                    DispatchQueue.main.async { self.performSegue(withIdentifier: "UnwindToMedia", sender: nil) }
                }
            }
        }
    }

}
