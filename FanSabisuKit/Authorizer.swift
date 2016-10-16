import Foundation
import CommonCrypto

public class Authorizer {

    let session: URLSession
    var oauthToken: String?

    public init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }

    public func requestToken(completionHandler: (Result<String>) -> Void) {
        let url = URL(string: "https://api.twitter.com/oauth/request_token")!
        let header = authorizationHeader(with: url, oauth_params: ["oauth_callback": "fansabisu://oauth"])

        var request = URLRequest(url: url)
        request.addValue(header, forHTTPHeaderField: "Authorization")
        request.addValue("*/*", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            print(data)
        }
        dataTask.resume()
    }

    func authorizationHeader(with url: URL, oauth_params: [String: String]?) -> String {
        let nonce = Data.nonce()
        let timestamp = String(Int64(Date().timeIntervalSince1970))
        var parameters = ["oauth_consumer_key": TwitterCredentials.consumerKey,
                          "oauth_nonce": nonce,
                          "oauth_signature_method": "HMAC-SHA1",
                          "oauth_timestamp": timestamp,
                          "oauth_version": "1.0",
                          ]
        oauth_params?.forEach { (key, value) in
            parameters.updateValue(value, forKey: key)
        }

        let signature = Signature(with: parameters, url: url, httpMethod: "POST", consumerSecret: TwitterCredentials.consumerSecret, oauthTokenSecret: nil).generate()
        var header = ""
        header.append("OAuth ")

        oauth_params?.forEach { (key, value) in
            header.append(key.percentEncoded())
            header.append("=\"")
            header.append(value.percentEncoded())
            header.append("\", ")
        }

        header.append("oauth_consumer_key".percentEncoded())
        header.append("=\"")
        header.append(TwitterCredentials.consumerKey.percentEncoded())
        header.append("\", ")

        header.append("oauth_nonce".percentEncoded())
        header.append("=\"")
        header.append(nonce.percentEncoded())
        header.append("\", ")

        header.append("oauth_signature".percentEncoded())
        header.append("=\"")
        header.append(signature.percentEncoded())
        header.append("\", ")

        header.append("oauth_signature_method".percentEncoded())
        header.append("=\"")
        header.append("HMAC-SHA1".percentEncoded())
        header.append("\", ")

        header.append("oauth_timestamp".percentEncoded())
        header.append("=\"")
        header.append(timestamp.percentEncoded())
        header.append("\", ")

        if let oauthToken = oauthToken {
            header.append("oauth_token".percentEncoded())
            header.append("=\"")
            header.append(oauthToken.percentEncoded())
            header.append("\", ")
        }

        header.append("oauth_version".percentEncoded())
        header.append("=\"")
        header.append("1.0".percentEncoded())
        header.append("\"")

        return header
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
