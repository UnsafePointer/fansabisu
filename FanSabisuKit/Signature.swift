import Foundation
import CommonCrypto

// Class designed following: https://dev.twitter.com/oauth/overview/creating-signatures

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
            $0.percentEncoded()
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
            parameterString.append(value.percentEncoded())
            signatureParameters.append(parameterString)
        }
        let parameterString = signatureParameters.joined(separator: "&")
        return parameterString
    }

    func signatureBase(with parameterString: String) -> String {
        var signatureBaseString = httpMethod.uppercased()
        signatureBaseString.append("&")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        let percentEncodedURL = components!.string!.percentEncoded()
        signatureBaseString.append(percentEncodedURL)
        signatureBaseString.append("&")
        let percentEncodedParameterString = parameterString.percentEncoded()
        signatureBaseString.append(percentEncodedParameterString)
        return signatureBaseString
    }

    func signingKey() -> String {
        var signingKey = consumerSecret.percentEncoded()
        signingKey.append("&")
        if let oauthTokenSecret = oauthTokenSecret {
            signingKey.append(oauthTokenSecret.percentEncoded())
        }
        return signingKey
    }

    func generate() -> String {
        let parameterString = self.parameterString()
        let signatureBaseString = self.signatureBase(with: parameterString)
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

