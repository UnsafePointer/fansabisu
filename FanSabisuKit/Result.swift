import Foundation

public enum Result<T> {
    case Success(T)
    case Failure(Error)
}

public extension Result {
    func resolve() throws -> T {
        switch self {
        case Result.Success(let value): return value
        case Result.Failure(let error): throw error
        }
    }
}
