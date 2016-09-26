import UIKit
import MobileCoreServices
import FanSabisuKit

class ActionViewController: UIViewController {

    @IBOutlet var activityIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        var found = false
        
        outer:
            for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
                if let attachments = item.attachments {
                    for itemProvider in attachments as! [NSItemProvider] {
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypeURL)) {
                            itemProvider.loadItem(forTypeIdentifier: String(kUTTypeURL), options: nil, completionHandler: { (item, error) in
                                let URL = item as! URL
                                OperationQueue.main.addOperation {
                                    self.itemLoadCompletedWithPreprocessingResults(URL)
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
    
    func itemLoadCompletedWithPreprocessingResults(_ urlPreprocessingResults: URL) {
        self.activityIndicator?.startAnimating()
        let mediaDownloader = MediaDownloader()
        mediaDownloader.downloadMedia(tweetURLString: urlPreprocessingResults.absoluteString) { (url, error) in
            let videoProcessor = VideoProcessor()
            videoProcessor.processVideo(fileURL: url!, completionHandler: { (error) in
                self.done()
            })
        }
    }
    
    @IBAction func done() {
        self.activityIndicator?.stopAnimating()
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

}
