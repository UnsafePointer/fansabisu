import Foundation

public enum MediaDownloaderError: Error {
    case invalidURL
    case requestFailed
    case tooManyRequests
}

public class MediaDownloader {
    
    let session: URLSession
    let responseParser: ResponseParser
    
    public init(session: URLSession) {
        self.session = session
        responseParser = ResponseParser()
    }
    
    public func downloadMedia(with tweetURL: URL, completionHandler: @escaping (Result<URL>) -> Void) {
        guard let tweetID = tweetURL.pathComponents.last else {
            return completionHandler(Result.failure(MediaDownloaderError.invalidURL))
        }
        let URLString = "https://api.twitter.com/1.1/statuses/show.json?id=".appending(tweetID)
        guard let requestURL = URL(string: URLString) else {
            return completionHandler(Result.failure(MediaDownloaderError.invalidURL))
        }
        let authorizer = Authorizer(session: session)
        authorizer.buildRequest(for: requestURL) { (result) in
            do {
                let request = try result.resolve()
                let dataTask = self.session.dataTask(with: request) { (data, response, error) in
                    if (response as? HTTPURLResponse)?.statusCode == 429 {
                        return DispatchQueue.main.async { completionHandler(Result.failure(MediaDownloaderError.tooManyRequests)) }
                    }
                    if (response as? HTTPURLResponse)?.statusCode != 200 {
                        return DispatchQueue.main.async { completionHandler(Result.failure(MediaDownloaderError.requestFailed)) }
                    }
                    if let error = error {
                        return DispatchQueue.main.async { completionHandler(Result.failure(error)) }
                    }
                    guard let data = data else {
                        return DispatchQueue.main.async { completionHandler(Result.failure(MediaDownloaderError.requestFailed)) }
                    }

                    let url = self.responseParser.parseStatus(with: data)
                    switch url {
                    case .success(let result):
                        self.downloadVideo(with: result, completionHandler: { (result) in
                            DispatchQueue.main.async { completionHandler(result) }
                        })
                    case .failure(let error):
                        return DispatchQueue.main.async { completionHandler(Result.failure(error)) }
                    }
                }
                dataTask.resume()
            } catch TokenProviderError.tooManyRequests {
                return completionHandler(Result.failure(MediaDownloaderError.tooManyRequests))
            } catch {
                return completionHandler(Result.failure(MediaDownloaderError.requestFailed))
            }
        }
    }

    func downloadVideo(with videoUrl: URL, completionHandler: @escaping (Result<URL>) -> Void) {
        let dataTask = session.downloadTask(with: videoUrl) { (location, response, error) in
            if let error = error {
                return completionHandler(Result.failure(error))
            }
            let temporaryDirectoryFilePath = URL(fileURLWithPath: NSTemporaryDirectory())
            guard let response = response else {
                return completionHandler(Result.failure(MediaDownloaderError.requestFailed))
            }
            guard let location = location else {
                return completionHandler(Result.failure(MediaDownloaderError.requestFailed))
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
            completionHandler(Result.success(destinationUrl))
        }
        dataTask.resume()
    }

}
