import UIKit
import Foundation
import Photos
import FanSabisuKit

class MediaDetailViewController: GAITrackedViewController {

    var asset: PHAsset?
    @IBOutlet var imageView: UIImageView?
    var information: Dictionary<String, Any>?
    var temporaryEditorResults: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localizedString(for: "DETAILS")
        self.screenName = "Details"
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        manager.requestImageData(for: asset!, options: options) { (data, dataUTI, orientation, info) in
            if let data = data {
                let result = UIImage.animatedImage(with: data)
                self.imageView?.image = result.0
                self.information = result.1
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditPreview" {
            let controller = segue.destination as! PreviewViewController
            controller.url = temporaryEditorResults
        }
    }

    func displayInformation() {
        let manager = PHImageManager.default()
        manager.requestImageData(for: asset!, options: nil) { (data, dataUTI, orientation, info) in
            let size = ByteCountFormatter.string(fromByteCount: Int64(data!.count), countStyle: .file)
            var message = String(format: String.localizedString(for: "FILE_SIZE"), size)
            if let information = self.information {
                message = message.appendingFormat(String.localizedString(for: "FILE_FRAMES"), information[UIImage.GIFInformationKey.frames.rawValue] as! Int)
                message = message.appendingFormat(String.localizedString(for: "FILE_DURATION"), information[UIImage.GIFInformationKey.duration.rawValue] as! Double)
                message = message.appendingFormat(String.localizedString(for: "FILE_FPS"), information[UIImage.GIFInformationKey.fps.rawValue] as! Int)
            }
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
        controller.addAction(UIAlertAction(title: String.localizedString(for: "EDIT"), style: .default, handler: { (action) in
            self.edit(sender: sender)
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

    func edit(sender: UIBarButtonItem) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: String.localizedString(for: "CANCEL"), style: .cancel, handler: { (action) in
        }))
        controller.addAction(UIAlertAction(title: String.localizedString(for: "2XSPEEDUP"), style: .default, handler: { (action) in
            self.previewChanges(edit: .speedup)
        }))
        controller.addAction(UIAlertAction(title: String.localizedString(for: "2XSLOWDOWN"), style: .default, handler: { (action) in
            self.previewChanges(edit: .slowdown)
        }))
        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.popoverPresentationController?.barButtonItem = sender
        }
        present(controller, animated: true, completion: nil)
    }

    func previewChanges(edit: Edit) {
        guard let data = self.information?[UIImage.GIFInformationKey.data.rawValue] as? Data else {
            self.presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "EDIT_FAILED"), actionHandler: nil)
            return
        }
        let editor = Editor(data: data, edit: edit)
        if let result = editor.apply() {
            self.temporaryEditorResults = result
            performSegue(withIdentifier: "EditPreview", sender: self)
        } else {
            self.presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "EDIT_FAILED"), actionHandler: nil)
        }
    }

}
