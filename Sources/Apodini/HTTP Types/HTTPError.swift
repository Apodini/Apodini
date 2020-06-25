enum HTTPError: Error {
    case ok
    case notImplemented
    case internalServerError(reason: String)
}
