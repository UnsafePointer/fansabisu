import Foundation

// Class designed following: https://dev.twitter.com/oauth/overview/percent-encoding-parameters

extension String {

    func percentEncoded() -> String {
        let characterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: characterSet)!
    }
    
}
