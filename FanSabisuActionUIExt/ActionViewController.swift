import UIKit
import MobileCoreServices
import FanSabisuKit

class ActionViewController: UIViewController {

    @IBOutlet var activityIndicator: UIActivityIndicatorView?
    @IBOutlet var imageView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localizedString(for: "DOWNLOADING")
        self.navigationController?.navigationBar.tintColor = UIColor.appearanceColor()
    
        var found = false
        
        outer:
            for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
                if let attachments = item.attachments {
                    for itemProvider in attachments as! [NSItemProvider] {
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypeURL)) {
                            itemProvider.loadItem(forTypeIdentifier: String(kUTTypeURL), options: nil, completionHandler: { (item, error) in
                                let url = item as! URL
                                if !url.isValidURL {
                                    let message = String(format: String.localizedString(for: "INVALID_URL"), url.absoluteString)
                                    self.showError(message: message)
                                } else {
                                    OperationQueue.main.addOperation {
                                        self.itemLoadCompletedWithPreprocessingResults(url)
                                    }
                                }
                            })
                            found = true
                            break outer
                        }
                    }
                }
        }
        
        if !found {
            self.done()
        }
    }

    func showError(message: String) {
        let controller = UIAlertController(title: String.localizedString(for: "ERROR_TITLE"), message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: String.localizedString(for: "ACCEPT"), style: .default, handler: { (action) in
            self.done()
        }))
        present(controller, animated: true, completion: nil)
    }
    
    func itemLoadCompletedWithPreprocessingResults(_ urlPreprocessingResults: URL) {
        self.activityIndicator?.startAnimating()
        let mediaDownloader = MediaDownloader()
        mediaDownloader.downloadMedia(with: urlPreprocessingResults, completionHandler: { (result) in
            guard let videoUrl = try? result.resolve() else {
                return self.showError(message: String.localizedString(for: "DOWNLOAD_VIDEO_ERROR"))
            }
            let videoProcessor = VideoProcessor()
            videoProcessor.processVideo(with: videoUrl, completionHandler: { (result) in
                guard let url = try? result.resolve() else {
                    return self.showError(message: String.localizedString(for: "PROCESS_VIDEO_ERROR"))
                }
                if let data = try? Data(contentsOf: url) {
                    self.updateInterface(with: data)
                } else {
                    self.done()
                }
            })
        })
    }

    func updateInterface(with data: Data) {
        self.title = String.localizedString(for: "COMPLETE")
        self.activityIndicator?.stopAnimating()
        self.imageView?.image = UIImage.animatedImage(with: data).0

        self.navigationItem.setLeftBarButton(nil, animated: true)
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        self.navigationItem.setRightBarButton(barButtonItem, animated: true)
    }

    @IBAction func done() {
        self.activityIndicator?.stopAnimating()
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

}
