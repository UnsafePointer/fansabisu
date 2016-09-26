import Foundation

class TokenProvider {
    
    let consumerKey: String = "5aRrYugWlofJe1g1Wy5sZrBno"
    let consumerSecret: String = "wCoXxVimmhZkbO50pFV2SOkVbaOOdGWDAqIlpTjngqIwpLCGcm"
    let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func provideToken(completionHandler: @escaping (String?, NSError?) -> Void) {
        if let accessToken = UserDefaults.standard.string(forKey: "FanSabisuTwitterToken") {
            completionHandler(accessToken, nil)
            return
        }
        
        let input = consumerKey.appending(":").appending(consumerSecret)
        let credentials = input.base64encode()
        var request = URLRequest(url: URL(string: "https://api.twitter.com/oauth2/token")!)
        request.addValue("Basic ".appending(credentials), forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = "grant_type=client_credentials".data(using: String.Encoding.utf8)
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            let jsonObject = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! Dictionary<String, String>
            let accessToken = jsonObject["access_token"]
            UserDefaults.standard.set(accessToken, forKey: "FanSabisuTwitterToken")
            completionHandler(accessToken, nil)
        }
        dataTask.resume()
    }
}

extension String {
    func base64encode() -> String {
        let inputData = self.data(using: String.Encoding.utf8)!
        let data = inputData.base64EncodedData(options: NSData.Base64EncodingOptions(rawValue: 0))
        let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
        return string
    }
}
