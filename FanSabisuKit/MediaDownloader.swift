import Foundation

public enum MediaDownloaderError: Error {
    case InvalidURL
    case RequestFailed
}

public class MediaDownloader {
    
    let session: URLSession
    let tokenProvider: TokenProvider
    let responseParser: ResponseParser
    
    public init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
        tokenProvider = TokenProvider(session: session)
        responseParser = ResponseParser()
    }
    
    public func downloadMedia(with tweetURL: URL, completionHandler: @escaping (Result<URL>) -> Void) {
        tokenProvider.provideToken { (result) in
            guard let token = try? result.resolve() else {
                return completionHandler(Result.Failure(MediaDownloaderError.RequestFailed))
            }
            guard let tweetID = tweetURL.pathComponents.last else {
                return completionHandler(Result.Failure(MediaDownloaderError.InvalidURL))
            }
            let URLString = "https://api.twitter.com/1.1/statuses/show.json?id=".appending(tweetID)
            guard let requestURL = URL(string: URLString) else {
                return completionHandler(Result.Failure(MediaDownloaderError.InvalidURL))
            }
            var request = URLRequest(url: requestURL)
            request.addValue("Bearer ".appending(token), forHTTPHeaderField: "Authorization")
            let dataTask = self.session.dataTask(with: request) { (data, URLResponse, error) in
                if let error = error {
                    return completionHandler(Result.Failure(error))
                }
                guard let data = data else {
                    return completionHandler(Result.Failure(MediaDownloaderError.RequestFailed))
                }

                let url = self.responseParser.parseStatus(with: data)
                switch url {
                case .Success(let result):
                    self.downloadVideo(with: result, completionHandler: { (result) in
                        completionHandler(result)
                    })
                case .Failure(let error):
                    return completionHandler(Result.Failure(error))
                }


            }
            dataTask.resume()
        }
    }
    
    func downloadVideo(with videoUrl: URL, completionHandler: @escaping (Result<URL>) -> Void) {
        let task = session.downloadTask(with: videoUrl) { (location, response, error) in
            if let error = error {
                return completionHandler(Result.Failure(error))
            }
            let temporaryDirectoryFilePath = URL(fileURLWithPath: NSTemporaryDirectory())
            guard let response = response else {
                return completionHandler(Result.Failure(MediaDownloaderError.RequestFailed))
            }
            guard let location = location else {
                return completionHandler(Result.Failure(MediaDownloaderError.RequestFailed))
            }
            let suggestedFilename: String
            if let value = response.suggestedFilename {
                suggestedFilename = value
            } else {
                suggestedFilename = videoUrl.lastPathComponent
            }
            let destinationUrl = temporaryDirectoryFilePath.appendingPathComponent(suggestedFilename)
            if FileManager().fileExists(atPath: destinationUrl.path) {
                print("MediaDownloader: The file \(suggestedFilename) already exists at path \(destinationUrl.path)")
            } else {
                let data = try? Data(contentsOf: location)
                try? data?.write(to: destinationUrl, options: Data.WritingOptions.atomic)
            }
            completionHandler(Result.Success(destinationUrl))
        }
        task.resume()
    }

}
