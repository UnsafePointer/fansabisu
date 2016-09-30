import UIKit
import MobileCoreServices
import FanSabisuKit

class ActionViewController: UIViewController {

    @IBOutlet var activityIndicator: UIActivityIndicatorView?
    @IBOutlet var imageView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        var found = false
        
        outer:
            for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
                if let attachments = item.attachments {
                    for itemProvider in attachments as! [NSItemProvider] {
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypeURL)) {
                            itemProvider.loadItem(forTypeIdentifier: String(kUTTypeURL), options: nil, completionHandler: { (item, error) in
                                let url = item as! URL
                                if !url.isValidURL {
                                    self.showError(with: url)
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

    func showError(with url: URL) {
        let message = "Invalid URL found: \(url.absoluteString)"
        let controller = UIAlertController(title: "An error has occurred", message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.done()
        }))
        present(controller, animated: true, completion: nil)
    }
    
    func itemLoadCompletedWithPreprocessingResults(_ urlPreprocessingResults: URL) {
        self.activityIndicator?.startAnimating()
        let mediaDownloader = MediaDownloader()
        mediaDownloader.downloadMedia(tweetURLString: urlPreprocessingResults.absoluteString) { (url, error) in
            let videoProcessor = VideoProcessor()
            videoProcessor.processVideo(fileURL: url!, completionHandler: { (temporaryUrl, error) in
                if let data = try? Data(contentsOf: temporaryUrl!) {
                    self.updateInterface(with: data)
                } else {
                    self.done()
                }
            })
        }
    }

    func updateInterface(with data: Data) {
        self.title = "Complete"
        self.activityIndicator?.stopAnimating()
        self.imageView?.image = UIImage.animatedImage(with: data)

        self.navigationItem.setLeftBarButton(nil, animated: true)
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        self.navigationItem.setRightBarButton(barButtonItem, animated: true)
    }

    @IBAction func done() {
        self.activityIndicator?.stopAnimating()
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

}
