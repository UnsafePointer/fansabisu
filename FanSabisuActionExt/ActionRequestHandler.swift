//
//  ActionRequestHandler.swift
//  FanSabisuActionExt
//
//  Created by Renzo Crisóstomo on 25/09/16.
//  Copyright © 2016 Renzo Crisóstomo. All rights reserved.
//

import UIKit
import MobileCoreServices

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
                                let URL = item as! NSURL
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
            self.doneWithResults(nil)
        }
    }
    
    func itemLoadCompletedWithPreprocessingResults(_ URLPreprocessingResults: NSURL?) {
        self.doneWithResults(nil)
    }
    
    func doneWithResults(_ results: UIImage?) {
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        self.extensionContext = nil
    }

}
