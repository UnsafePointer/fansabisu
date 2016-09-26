import UIKit
import MobileCoreServices
import FanSabisuKit

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?
    
    func beginRequest(with context: NSExtensionContext) {
        self.extensionContext = context
        var found = false
        
        outer:
            for item in context.inputItems as! [NSExtensionItem] {
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
        let mediaDownloader = MediaDownloader()
        mediaDownloader.downloadMedia(tweetURLString: urlPreprocessingResults.absoluteString) { (url, error) in
            let videoProcessor = VideoProcessor()
            videoProcessor.processVideo(fileURL: url!, completionHandler: { (error) in
                self.done()
            })
        }
    }
    
    func done() {
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        self.extensionContext = nil
    }

}
