import Foundation

enum TokenProviderError: Error {
    case InvalidInput
    case RequestFailed
}

class TokenProvider {
    
    let consumerKey: String = "5aRrYugWlofJe1g1Wy5sZrBno"
    let consumerSecret: String = "wCoXxVimmhZkbO50pFV2SOkVbaOOdGWDAqIlpTjngqIwpLCGcm"
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
            return completionHandler(Result.Success(accessToken))
        }
        
        let input = consumerKey.appending(":").appending(consumerSecret)
        guard let credentials = input.base64encode() else {
            return completionHandler(Result.Failure(TokenProviderError.InvalidInput))
        }
        var request = URLRequest(url: URL(string: "https://api.twitter.com/oauth2/token")!)
        request.addValue("Basic ".appending(credentials), forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = "grant_type=client_credentials".data(using: String.Encoding.utf8)
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                return DispatchQueue.main.async { completionHandler(Result.Failure(error)) }
            }
            guard let data = data else {
                return DispatchQueue.main.async { completionHandler(Result.Failure(TokenProviderError.RequestFailed)) }
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
