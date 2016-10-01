import UIKit

extension UIViewController {

    func presentMessage(title: String, message: String, actionHandler: (() -> ())?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: String.localizedString(for: "ACCEPT"), style: .default, handler: { (action) in
            actionHandler?()
        })
        alertController.addAction(alertAction)
        self.present(alertController, animated: true, completion: nil)
    }

}
