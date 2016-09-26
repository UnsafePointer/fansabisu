import Foundation

public class MediaDownloader {
    
    let session: URLSession
    let tokenProvider: TokenProvider
    
    public init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
        tokenProvider = TokenProvider(session: session)
    }
    
    public func downloadMedia(tweetURLString: String, completionHandler: @escaping (URL?, NSError?) -> Void) {
        tokenProvider.provideToken { (token, error) in
            let tweetURL = URL(string: tweetURLString)
            let tweetID = tweetURL!.pathComponents.last!
            let URLString = "https://api.twitter.com/1.1/statuses/show.json?id=".appending(tweetID)
            let requestURL = URL(string: URLString)
            var request = URLRequest(url: requestURL!)
            request.addValue("Bearer ".appending(token!), forHTTPHeaderField: "Authorization")
            let dataTask = self.session.dataTask(with: request) { (data, URLResponse, error) in
                let jsonObject = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! Dictionary<String, Any>
                let extendedEntities = jsonObject["extended_entities"] as! Dictionary<String, Any>
                let media = extendedEntities["media"] as! Array<Dictionary<String, Any>>
                for item in media {
                    let type = item["type"] as! String
                    if type == "animated_gif" {
                        let videoInfo = item["video_info"] as! Dictionary<String, Any>
                        let variants = videoInfo["variants"] as! Array<Dictionary<String, Any>>
                        let contentType = variants.first!["content_type"] as! String
                        if contentType == "video/mp4" {
                            let mediaUrl = variants.first!["url"] as! String
                            self.downloadVideo(mediaUrl: mediaUrl, completionHandler: { (url, error) in
                                completionHandler(url, nil)
                            })
                        }
                    }
                }
            }
            dataTask.resume()
        }
    }
    
    func downloadVideo(mediaUrl: String, completionHandler: @escaping (URL?, NSError?) -> Void) {
        let task = session.downloadTask(with: URL(string: mediaUrl)!) { (url, response, error) in
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
            let destinationUrl = documentsUrl.appendingPathComponent(String(response!.suggestedFilename!))
            if FileManager().fileExists(atPath: destinationUrl!.path) {
                print("The file already exists at path")
            } else {
                let data = try! Data(contentsOf: response!.url!)
                try! data.write(to: destinationUrl!, options: Data.WritingOptions.atomic)
            }
            completionHandler(destinationUrl, nil)
        }
        task.resume()
    }

}
