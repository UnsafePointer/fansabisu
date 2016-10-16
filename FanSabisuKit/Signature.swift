import Foundation
import CommonCrypto

class Signature {

    let parameters: [String: String]
    let url: URL
    let httpMethod: String
    let consumerSecret: String
    let oauthTokenSecret: String?

    init(with parameters: [String: String], url: URL, httpMethod: String, consumerSecret: String, oauthTokenSecret: String?) {
        self.parameters = parameters
        self.url = url
        self.httpMethod = httpMethod
        self.consumerSecret = consumerSecret
        self.oauthTokenSecret = oauthTokenSecret
    }

    func parameterString() -> String {
        let sortedKeys = parameters.keys.map({
            $0.urlEncodedString()
        }).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        var signatureParameters = [String]()
        for key in sortedKeys {
            var parameterString = ""
            parameterString.append(key)
            parameterString.append("=")
            let originalKey = key.removingPercentEncoding!
            let value = parameters[originalKey]!
            parameterString.append(value.urlEncodedString())
            signatureParameters.append(parameterString)
        }
        let parameterString = signatureParameters.joined(separator: "&")
        return parameterString
    }

    func signatureBaseString(with parameterString: String) -> String {
        var signatureBaseString = httpMethod.uppercased()
        signatureBaseString.append("&")
        let percentEncodedURL = url.absoluteString.urlEncodedString()
        signatureBaseString.append(percentEncodedURL)
        signatureBaseString.append("&")
        let percentEncodedParameterString = parameterString.urlEncodedString()
        signatureBaseString.append(percentEncodedParameterString)
        return signatureBaseString
    }

    func signingKey() -> String {
        var signingKey = consumerSecret.urlEncodedString()
        signingKey.append("&")
        if let oauthTokenSecret = oauthTokenSecret {
            signingKey.append(oauthTokenSecret.urlEncodedString())
        }
        return signingKey
    }

    func generate() -> String {
        let parameterString = self.parameterString()
        let signatureBaseString = self.signatureBaseString(with: parameterString)
        let signingKey = self.signingKey()
        let signature = hmac(with: signatureBaseString, key: signingKey)
        return signature.dataFromHexadecimalString().base64EncodedString()
    }

    func hmac(with signatureBase: String, key: String) -> String {
        let value = signatureBase.cString(using: .utf8)
        let length = Int(signatureBase.lengthOfBytes(using: .utf8))
        let digestLength = Int(CC_SHA1_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLength)

        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), key.cString(using: String.Encoding.utf8)!, Int(key.lengthOfBytes(using: .utf8)), value, length, result)

        let hash = NSMutableString()
        for index in 0..<digestLength {
            hash.appendFormat("%02X", result[index])
        }


        result.deallocate(capacity: digestLength)

        return String(hash)
    }

}

extension String {

    func urlEncodedString() -> String {
        let characterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.addingPercentEncoding(withAllowedCharacters: characterSet)!
    }

}

extension String {

    func dataFromHexadecimalString() -> Data {
        var data = Data(capacity: characters.count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, characters.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }

        return data
    }
}

