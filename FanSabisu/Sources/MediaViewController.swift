import UIKit
import Photos
import FanSabisuKit

class MediaViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView?
    let itemsPerRow: CGFloat = 3
    let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var dataSource: [PHAsset] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        PHPhotoLibrary.requestAuthorization { (status) in
            if status != .authorized {
                // TO-DO: Present error
            } else {
                self.loadAssets()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MediaDetail" {
            let controller = segue.destination as! MediaDetailViewController
            let indexPath = collectionView?.indexPath(for: sender as! UICollectionViewCell)
            let asset = dataSource[indexPath!.row]
            controller.asset = asset
        }
    }

    @IBAction func checkPasteboard() {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            // TO-DO: Present error
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
    
    func loadAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        let fetchResult = PHAsset.fetchAssets(with: options)
        fetchResult.enumerateObjects({ (asset, index, _) in
            let resources = PHAssetResource.assetResources(for: asset)
            for (_, resource) in resources.enumerated() {
                if resource.uniformTypeIdentifier == "com.compuserve.gif" {
                    self.dataSource.append(asset)
                    break
                }
            }
        })
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }

}

extension MediaViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AssetCell", for: indexPath) as! MediaCell
        cell.asset = dataSource[indexPath.row]
        return cell
    }

}

extension MediaViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "MediaDetail", sender: collectionView.cellForItem(at: indexPath))
    }

}

extension MediaViewController: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow

        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }

}
