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

    public static let applicationDidReceiveOAuthCallback = "applicationDidReceiveOAuthCallback"

    let session: URLSession
    var oauthToken: String?

    public init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }

    public func requestOAuth(presentingViewController: UIViewController, completionHandler: @escaping (Result<OAuth>) -> Void) {
        let url = URL(string: "https://api.twitter.com/oauth/request_token")!
        let header = authorizationHeader(with: url, oauth_params: ["oauth_callback": "fansabisu://oauth"])

        var request = URLRequest(url: url)
        request.addValue(header, forHTTPHeaderField: "Authorization")
        request.addValue("*/*", forHTTPHeaderField: "Accept")
        request.httpMethod = "POST"
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                return completionHandler(Result.failure(AuthorizerError.couldNotAuthenticate))
            }
            guard let responseString = String(data: data, encoding: .utf8) else {
                return completionHandler(Result.failure(AuthorizerError.couldNotParseResponse))
            }
            let accessToken = RequestToken(response: responseString)
            guard let oauthToken = accessToken.oauthToken else {
                return completionHandler(Result.failure(AuthorizerError.couldNotParseResponse))
            }
            guard let url = URL(string: "https://api.twitter.com/oauth/authenticate?oauth_token=".appending(oauthToken)) else {
                return completionHandler(Result.failure(AuthorizerError.couldNotBuildUrl))
            }
            let safariViewController = SFSafariViewController(url: url)
            presentingViewController.present(safariViewController, animated: true, completion: nil)

            FSKNotificationCenter.default.registerNotificationName(Authorizer.applicationDidReceiveOAuthCallback) { (parameters) in
                FSKNotificationCenter.default.unregisterNotificationName(Authorizer.applicationDidReceiveOAuthCallback)

                guard let query = parameters?["query"] as? String else {
                    return completionHandler(Result.failure(AuthorizerError.couldNotCompleteOAuth))
                }
                let tokenVerifier = TokenVerifier(response: query)
                let url = URL(string: "https://api.twitter.com/oauth/access_token")!

                guard let oauthToken = tokenVerifier.oauthToken, let oauthVerififer = tokenVerifier.oauthVerififer else {
                    return completionHandler(Result.failure(AuthorizerError.couldNotParseResponse))
                }

                let header = self.authorizationHeader(with: url, oauth_params: ["oauth_token": oauthToken])

                var request = URLRequest(url: url)
                request.addValue(header, forHTTPHeaderField: "Authorization")
                request.addValue("*/*", forHTTPHeaderField: "Accept")
                request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.addValue(String(oauthVerififer.characters.count), forHTTPHeaderField: "Content-Length")
                request.httpMethod = "POST"
                request.httpBody = "oauth_verifier=".appending(oauthVerififer).data(using: .utf8)
                let dataTask = self.session.dataTask(with: request) { (data, response, error) in
                    guard let data = data else {
                        return completionHandler(Result.failure(AuthorizerError.couldNotAuthenticate))
                    }
                    guard let responseString = String(data: data, encoding: .utf8) else {
                        return completionHandler(Result.failure(AuthorizerError.couldNotParseResponse))
                    }
                    let oauth = OAuth(response: responseString)
                    completionHandler(Result.success(oauth))
                }
                dataTask.resume()
            }
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

    let oauthToken: String?
    let oauthTokenSecret: String?
    let oauthCallbackConfirmed: Bool?

    init(response: String) {
        let parsedInfo = response.parse()
        self.oauthToken = parsedInfo["oauth_token"]
        self.oauthTokenSecret = parsedInfo["oauth_token_secret"]
        self.oauthCallbackConfirmed = parsedInfo["oauth_callback_confirmed"] == "true"
    }
}

struct TokenVerifier {
    let oauthToken: String?
    let oauthVerififer: String?

    init(response: String) {
        let parsedInfo = response.parse()
        self.oauthToken = parsedInfo["oauth_token"]
        self.oauthVerififer = parsedInfo["oauth_verifier"]
    }
}

public struct OAuth {
    public let oauthToken: String?
    public let oauthTokenSecret: String?
    public let userID: String?
    public let screenName: String?

    init(response: String) {
        let parsedInfo = response.parse()
        self.oauthToken = parsedInfo["oauth_token"]
        self.oauthTokenSecret = parsedInfo["oauth_token_secret"]
        self.userID = parsedInfo["user_id"]
        self.screenName = parsedInfo["screen_name"]
    }

    init(oauthToken: String, oauthTokenSecret: String, userID: String, screenName: String) {
        self.oauthToken = oauthToken
        self.oauthTokenSecret = oauthTokenSecret
        self.userID = userID
        self.screenName = screenName
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

extension String {

    func parse() -> [String: String] {
        let components = self.components(separatedBy: "&")
        var parsedInfo = [String: String]()
        for component in components {
            let parsedComponent = component.components(separatedBy: "=")
            if let value = parsedComponent.last, let key = parsedComponent.first {
                parsedInfo.updateValue(value, forKey: key)
            }
        }
        return parsedInfo
    }

}
