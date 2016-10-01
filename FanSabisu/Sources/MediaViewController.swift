import UIKit
import Photos
import FanSabisuKit

class MediaViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView?
    let itemsPerRow: CGFloat = 3
    let sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    var dataSource: [PHAsset] = []
    var activityIndicatorView: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        setupActivityIndicator()
        PHPhotoLibrary.requestAuthorization { (status) in
            if status != .authorized {
                // TO-DO: Present error
            } else {
                self.loadAssets()
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillEnterForeground(notification:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
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

    func setupActivityIndicator() {
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicatorView?.startAnimating()
        navigationItem.setLeftBarButton(UIBarButtonItem(customView: activityIndicatorView!), animated: true)
    }

    func handleApplicationWillEnterForeground(notification: Notification) {
        loadAssets()
    }

    func processPasteboard() {
        guard let pasteboard = UIPasteboard.general.string else {
            presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "PASTEBOARD_NOT_FOUND"), actionHandler: nil)
            return
        }
        guard let url = URL(string: pasteboard) else {
            presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "CONTENTS_NOT_SUITABLE"), actionHandler: nil)
            return
        }
        if !url.isValidURL {
            let message = String(format: String.localizedString(for: "INVALID_URL"), url.absoluteString)
            presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: message, actionHandler: nil)
            return
        }
        let message = String(format: String.localizedString(for: "URL_FOUND"), url.absoluteString)
        let controller = UIAlertController(title: String.localizedString(for: "PASTEBOARD_FOUND"), message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: String.localizedString(for: "CANCEL"), style: .cancel, handler: nil))
        controller.addAction(UIAlertAction(title: String.localizedString(for: "DOWNLOAD"), style: .default, handler: { (action) in
            self.activityIndicatorView?.startAnimating()
            let mediaDownloader = MediaDownloader()
            mediaDownloader.downloadMedia(with: url, completionHandler: { (result) in
                guard let videoUrl = try? result.resolve() else {
                    self.activityIndicatorView?.stopAnimating()
                    return self.presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "DOWNLOAD_VIDEO_ERROR"), actionHandler: nil)
                }
                let videoProcessor = VideoProcessor()
                videoProcessor.processVideo(with: videoUrl, completionHandler: { (result) in
                    guard let _ = try? result.resolve() else {
                        self.activityIndicatorView?.stopAnimating()
                        return self.presentMessage(title: String.localizedString(for: "ERROR_TITLE"), message: String.localizedString(for: "PROCESS_VIDEO_ERROR"), actionHandler: nil)
                    }
                    self.activityIndicatorView?.stopAnimating()
                    self.presentMessage(title: String.localizedString(for: "FINISHED"), message: String.localizedString(for: "GIF_STORED"), actionHandler: nil)
                    self.loadAssets()
                })
            })
        }))
        present(controller, animated: true, completion: nil)
    }
    
    func loadAssets() {
        dataSource.removeAll()
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
            self.activityIndicatorView?.stopAnimating()
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
