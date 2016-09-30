import Foundation

public extension URL {

    var isValidURL: Bool {
        get {
            guard let host = self.host else {
                return false
            }
            if host != "twitter.com" {
                return false
            }
            guard let scheme = self.scheme else {
                return false
            }
            if !scheme.contains("http") {
                return false
            }
            if !path.contains("status") {
                return false
            }
            return true
        }
    }

}
