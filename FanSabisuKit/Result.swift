import Foundation

public enum Result<T> {
    case success(T)
    case failure(Error)
}

public extension Result {
    func resolve() throws -> T {
        switch self {
        case Result.success(let value): return value
        case Result.failure(let error): throw error
        }
    }
}
