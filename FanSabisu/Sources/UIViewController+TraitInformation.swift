import UIKit

extension UIViewController {

    func hasCompactHorizontalTrait() -> Bool {
        let compactHoriziontal = self.traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .compact))
        return compactHoriziontal
    }

    func hasUserInterfaceIdiomPadTrait() -> Bool {
        let userInterfaceIdiomPad = self.traitCollection.containsTraits(in: UITraitCollection(userInterfaceIdiom: .pad))
        return userInterfaceIdiomPad
    }
    
}
