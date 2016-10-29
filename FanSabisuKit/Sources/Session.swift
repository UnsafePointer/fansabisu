import Foundation

public class Session {
    public static let shared = URLSession(configuration: URLSessionConfiguration.ephemeral)
}
