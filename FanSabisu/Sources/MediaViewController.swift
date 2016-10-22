import UIKit
import Photos
import FanSabisuKit

class MediaViewController: UIViewController {

    @IBOutlet var collectionView: UICollectionView?
    var itemsPerRow: CGFloat?
    var dataSource: [PHAsset] = []
    var activityIndicatorView: UIActivityIndicatorView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localizedString(for: "MEDIA")
        setupItemsPerRow(with: self.view.frame.size)
        automaticallyAdjustsScrollViewInsets = false
        setupNavigationItems()
        PHPhotoLibrary.requestAuthorization { (status) in
            if status != .authorized {
                DispatchQueue.main.async {
                    self.presentAuthorizationError()
                }
            } else {
                self.loadAssets()
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if hasUserInterfaceIdiomPadTrait() {
            self.collectionView?.reloadSections(IndexSet(integer: 0))
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setupItemsPerRow(with: size)
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MediaDetail" {
            let controller = segue.destination as! MediaDetailViewController
            let indexPath = collectionView?.indexPath(for: sender as! UICollectionViewCell)
            let asset = dataSource[indexPath!.row]
            controller.asset = asset
        }
    }

    func checkPasteboard() {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            DispatchQueue.main.async {
                self.presentAuthorizationError()
            }
        } else {
            processPasteboard()
        }
    }

    func setupItemsPerRow(with viewSize: CGSize) {
        let landscape = viewSize.width > viewSize.height
        if hasUserInterfaceIdiomPadTrait() {
            if landscape {
                itemsPerRow = 7
            } else {
                itemsPerRow = 5
            }
        } else {
            if landscape {
                itemsPerRow = 7
            } else {
                itemsPerRow = 4
            }
        }
    }

    func presentAuthorizationError() {
        self.activityIndicatorView?.stopAnimating()
        self.presentMessage(title: String.localizedString(for: "AUTHORIZATION_NOT_GRANTED"), message: String.localizedString(for: "USAGE_DESCRIPTION"), actionHandler: {
            let url = URL(string: UIApplicationOpenSettingsURLString)!
            UIApplication.shared.openURL(url)
        })
    }

    func setupNavigationItems() {
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicatorView?.startAnimating()
        navigationItem.setLeftBarButton(UIBarButtonItem(customView: activityIndicatorView!), animated: true)

        let refreshBarButonItem = UIBarButtonItem(image: UIImage(named: "Refresh"), style: .plain, target: self, action: #selector(loadAssets))
        let pasteboardBarButonItem = UIBarButtonItem(image: UIImage(named: "Clipboard"), style: .plain, target: self, action: #selector(checkPasteboard))
        navigationItem.setRightBarButtonItems([refreshBarButonItem, pasteboardBarButonItem], animated: true)
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
            let mediaDownloader = MediaDownloader(session: URLSession.shared)
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
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
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
            self.collectionView?.reloadSections(IndexSet(integer: 0))
        }
    }

    @IBAction func unwindToMedia(sender: UIStoryboardSegue) {
        self.activityIndicatorView?.startAnimating()
        self.loadAssets()
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
        if hasCompactHorizontalTrait() {
            cell.imageView?.contentMode = .scaleAspectFill
        } else {
            cell.imageView?.contentMode = .scaleAspectFit
        }
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
        let interItemSpace: CGFloat
        if hasCompactHorizontalTrait() {
            interItemSpace = 1
        } else {
            if hasUserInterfaceIdiomPadTrait() {
                interItemSpace = 20
            } else {
                interItemSpace = 1
            }
        }

        let paddingSpace = interItemSpace * (itemsPerRow! + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow!

        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if hasCompactHorizontalTrait() {
            return .zero
        } else {
            return UIEdgeInsets.init(top: 16, left: 16, bottom: 16, right: 16)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if hasCompactHorizontalTrait() {
            return 1
        } else {
            return 10
        }
    }

}
