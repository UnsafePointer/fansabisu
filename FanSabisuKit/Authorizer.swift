import Foundation
import CommonCrypto

public class Authorizer {

    let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }

    public func requestToken(completionHandler: (Result<String>) -> Void) {
        let consumerKey = "5aRrYugWlofJe1g1Wy5sZrBno"
        let consumerSecret = "wCoXxVimmhZkbO50pFV2SOkVbaOOdGWDAqIlpTjngqIwpLCGcm"
        var parameters = ["oauth_callback": "fansabisu://callback",
                          "oauth_consumer_key": consumerKey,
                          "oauth_nonce": Data.nonce(),
                          "oauth_signature_method": "HMAC-SHA1",
                          "oauth_timestamp": String(Date().timeIntervalSince1970),
                          "oauth_version": "1.0",
                          ]
        let url = URL(string: "https://api.twitter.com/oauth/request_token")!
        let signature = Signature(with: parameters, url: url, httpMethod: "POST", consumerSecret: consumerSecret, oauthTokenSecret: nil)
        parameters["oauth_signature"] = signature.generate()
    }
}

extension Data {

    static func nonce() -> String {
        guard let data = NSMutableData(length: 32) else {
            return ""
        }
        if CCRandomGenerateBytes(data.mutableBytes, data.length) != CCRNGStatus(kCCSuccess) {
            return ""
        }
        let encondedData = data.base64EncodedString()
        let alphanumeric = encondedData.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "")
        return alphanumeric
    }

}
