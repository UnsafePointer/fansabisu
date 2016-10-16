import Foundation

enum TokenProviderError: Error {
    case invalidInput
    case requestFailed
}

class TokenProvider {

    let session: URLSession
    let responseParser: ResponseParser
    let userDefaults: UserDefaults
    
    init(session: URLSession) {
        self.session = session
        self.responseParser = ResponseParser()
        self.userDefaults = UserDefaults(suiteName: "group.com.ruenzuo.FanSabisu")!
    }
    
    func provideToken(with completionHandler: @escaping (Result<String>) -> Void) {
        if let accessToken = self.userDefaults.string(forKey: "FanSabisuTwitterToken") {
            return completionHandler(Result.success(accessToken))
        }
        
        let input = TwitterCredentials.consumerKey.appending(":").appending(TwitterCredentials.consumerSecret)
        guard let credentials = input.base64encode() else {
            return completionHandler(Result.failure(TokenProviderError.invalidInput))
        }
        var request = URLRequest(url: URL(string: "https://api.twitter.com/oauth2/token")!)
        request.addValue("Basic ".appending(credentials), forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = "grant_type=client_credentials".data(using: String.Encoding.utf8)
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                return DispatchQueue.main.async { completionHandler(Result.failure(error)) }
            }
            guard let data = data else {
                return DispatchQueue.main.async { completionHandler(Result.failure(TokenProviderError.requestFailed)) }
            }
            let result =  self.responseParser.parseToken(with: data)
            if let value = try? result.resolve() {
                self.userDefaults.set(value, forKey: "FanSabisuTwitterToken")
            }
            DispatchQueue.main.async { completionHandler(result) }
        }
        dataTask.resume()
    }
}

extension String {
    func base64encode() -> String? {
        let inputData = self.data(using: String.Encoding.utf8)
        guard let data = inputData?.base64EncodedData(options: Data.Base64EncodingOptions(rawValue: 0)) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
}
