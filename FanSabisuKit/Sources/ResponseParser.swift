import Foundation

enum ResponseParserError: Error {
    case invalidInput
    case notFound
}

class ResponseParser {

    func parseStatus(with response: Data) -> Result<URL> {
        let jsonObject = try? JSONSerialization.jsonObject(with: response, options: JSONSerialization.ReadingOptions.allowFragments) as? Dictionary<String, Any>
        let extendedEntities = jsonObject??["extended_entities"] as? Dictionary<String, Any>
        let media = extendedEntities?["media"] as? Array<Dictionary<String, Any>>

        guard let parsedMedia = media else {
            return Result.failure(ResponseParserError.invalidInput)
        }

        for item in parsedMedia {
            let type = item["type"] as? String
            if type == "animated_gif" {
                let videoInfo = item["video_info"] as? Dictionary<String, Any>
                let variants = videoInfo?["variants"] as? Array<Dictionary<String, Any>>
                let contentType = variants?.first?["content_type"] as? String
                if contentType == "video/mp4" {
                    let mediaUrl = variants?.first?["url"] as? String
                    if let mediaUrl = mediaUrl {
                        if let result = URL(string: mediaUrl) {
                            return Result.success(result)
                        }
                    }
                }
            }
        }

        return Result.failure(ResponseParserError.notFound)
    }

    func parseToken(with response: Data) -> Result<String> {
        let jsonObject = try? JSONSerialization.jsonObject(with: response, options: JSONSerialization.ReadingOptions.allowFragments) as? Dictionary<String, String>
        if let accessToken = jsonObject??["access_token"] {
            return Result.success(accessToken)
        } else {
            return Result.failure(ResponseParserError.invalidInput)
        }
    }

}
