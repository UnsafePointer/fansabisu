import Foundation
import CommonCrypto
import SafariServices

public enum AuthorizerError: Error {
    case couldNotAuthenticate
    case couldNotParseResponse
    case couldNotBuildUrl
    case couldNotCompleteOAuth
}

public class Authorizer {

    let session: URLSession
    var oauthToken: String?
    let presentingViewController: UIViewController
    let completionHandler: ((Result<String>) -> Void)

    public init(presentingViewController: UIViewController, completionHandler: @escaping (Result<String>) -> Void) {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
        self.presentingViewController = presentingViewController
        self.completionHandler = completionHandler
    }

    public func continueTokenRequest(with userInfo: [AnyHashable: Any]?) {
        guard let query = userInfo?["query"] as? String else {
            return self.completionHandler(Result.failure(AuthorizerError.couldNotCompleteOAuth))
        }
        let tokenVerifier = TokenVerifier(query: query)
        let url = URL(string: "https://api.twitter.com/oauth/access_token")!
        let header = authorizationHeader(with: url, oauth_params: ["oauth_token": tokenVerifier.oauthToken])

        var request = URLRequest(url: url)
        request.addValue(header, forHTTPHeaderField: "Authorization")
        request.addValue("*/*", forHTTPHeaderField: "Accept")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue(String(tokenVerifier.oauthVerififer.characters.count), forHTTPHeaderField: "Content-Length")
        request.httpMethod = "POST"
        request.httpBody = "oauth_verifier=".appending(tokenVerifier.oauthVerififer).data(using: .utf8)
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            print(data)
        }
        dataTask.resume()
    }

    public func requestToken() {
        let url = URL(string: "https://api.twitter.com/oauth/request_token")!
        let header = authorizationHeader(with: url, oauth_params: ["oauth_callback": "fansabisu://oauth"])

        var request = URLRequest(url: url)
        request.addValue(header, forHTTPHeaderField: "Authorization")
        request.addValue("*/*", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                return self.completionHandler(Result.failure(AuthorizerError.couldNotAuthenticate))
            }
            guard let responseString = String(data: data, encoding: .utf8) else {
                return self.completionHandler(Result.failure(AuthorizerError.couldNotParseResponse))
            }
            let accessToken = RequestToken(response: responseString)
            guard let url = URL(string: "https://api.twitter.com/oauth/authenticate?oauth_token=".appending(accessToken.oauthToken)) else {
                return self.completionHandler(Result.failure(AuthorizerError.couldNotBuildUrl))
            }
            let safariViewController = SFSafariViewController(url: url)
            self.presentingViewController.present(safariViewController, animated: true, completion: nil)
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

struct RequestToken {

    let oauthToken: String
    let oauthTokenSecret: String
    let oauthCallbackConfirmed: Bool

    init(response: String) {
        let components = response.components(separatedBy: "&")
        var parsedInfo = [String: String]()
        for component in components {
            let parsedComponent = component.components(separatedBy: "=")
            parsedInfo.updateValue(parsedComponent.last!, forKey: parsedComponent.first!)
        }
        self.oauthToken = parsedInfo["oauth_token"]!
        self.oauthTokenSecret = parsedInfo["oauth_token_secret"]!
        self.oauthCallbackConfirmed = parsedInfo["oauth_callback_confirmed"] == "true"
    }
}

struct TokenVerifier {
    let oauthToken: String
    let oauthVerififer: String

    init(query: String) {
        let components = query.components(separatedBy: "&")
        var parsedInfo = [String: String]()
        for component in components {
            let parsedComponent = component.components(separatedBy: "=")
            parsedInfo.updateValue(parsedComponent.last!, forKey: parsedComponent.first!)
        }
        self.oauthToken = parsedInfo["oauth_token"]!
        self.oauthVerififer = parsedInfo["oauth_verifier"]!
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
