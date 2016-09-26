import UIKit
import Photos
import FanSabisuKit

class MediaViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func checkPasteboard() {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ (status) in
                self.processPasteboard()
            })
        } else {
            processPasteboard()
        }
    }
    
    func processPasteboard() {
        guard let pasteboard = UIPasteboard.general.string else {
            presentAlert(title: "Welp!", message: "Pasteboard contents not found", actionHandler: nil)
            return
        }
        let message = "Found following URL ".appending(pasteboard).appending(". Procceed to download?")
        presentAlert(title: "Great!", message: message) {
            let mediaDownloader = MediaDownloader()
            mediaDownloader.downloadMedia(tweetURLString: pasteboard, completionHandler: { (url, error) in
                let videoProcessor = VideoProcessor()
                videoProcessor.processVideo(fileURL: url!, completionHandler: { (error) in
                    self.presentAlert(title: "Success", message: "GIF stored in camera roll", actionHandler: nil)
                })
            })
        }
    }
    
    func presentAlert(title: String, message: String, actionHandler: (() -> ())?) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                actionHandler?()
                alertController.dismiss(animated: true, completion: nil)
            })
            alertController.addAction(alertAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
}
