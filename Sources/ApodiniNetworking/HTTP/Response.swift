import NIO
import NIOHTTP1
import Foundation

public final class LKHTTPResponse {
    public var version: HTTPVersion
    public var status: HTTPResponseStatus
    public var headers: HTTPHeaders
    public var bodyStorage: LKRequestResponseBodyStorage
    
    public init(
        version: HTTPVersion,
        status: HTTPResponseStatus,
        headers: HTTPHeaders,
        bodyStorage: LKRequestResponseBodyStorage = .buffer()
    ) {
        self.version = version
        self.status = status
        self.headers = headers
        self.bodyStorage = bodyStorage
    }
}



/// A type which can be turned into a `HTTPResponse`
public protocol LKHTTPResponseConvertible {
    func makeHTTPResponse(for request: LKHTTPRequest) -> EventLoopFuture<LKHTTPResponse>
}


extension LKHTTPResponse: LKHTTPResponseConvertible {
    public func makeHTTPResponse(for request: LKHTTPRequest) -> EventLoopFuture<LKHTTPResponse> {
        return request.eventLoop.makeSucceededFuture(self)
    }
}

extension EventLoopFuture: LKHTTPResponseConvertible where Value: LKHTTPResponseConvertible {
    public func makeHTTPResponse(for request: LKHTTPRequest) -> EventLoopFuture<LKHTTPResponse> {
        // TODO should this handle errors?
        return self.flatMapAlways { (result: Result<Value, Error>) -> EventLoopFuture<LKHTTPResponse> in
            switch result {
            case .success(let value):
                return value.makeHTTPResponse(for: request)
            case .failure(let error):
                if let error = error as? LKHTTPResponseConvertible {
                    return error.makeHTTPResponse(for: request)
                } else {
                    return request.eventLoop.makeSucceededFuture(LKHTTPResponse(
                        version: request.version,
                        status: .internalServerError,
                        headers: [:],
                        bodyStorage: .buffer(initialValue: "\(error)") // TODO this risks leaking internal error info!!!
                    ))
                }
            }
        }
    }
}


extension String: LKHTTPResponseConvertible {
    public func makeHTTPResponse(for request: LKHTTPRequest) -> EventLoopFuture<LKHTTPResponse> {
        return request.eventLoop.makeSucceededFuture(LKHTTPResponse(
            version: request.version,
            status: .ok,
            headers: [:],
            bodyStorage: .buffer(initialValue: self)
        ))
    }
}

extension Data: LKHTTPResponseConvertible {
    public func makeHTTPResponse(for request: LKHTTPRequest) -> EventLoopFuture<LKHTTPResponse> {
        return request.eventLoop.makeSucceededFuture(LKHTTPResponse(
            version: request.version,
            status: .ok,
            headers: [:],
            bodyStorage: .buffer(initialValue: self)
        ))
    }
}

extension ByteBuffer: LKHTTPResponseConvertible {
    public func makeHTTPResponse(for request: LKHTTPRequest) -> EventLoopFuture<LKHTTPResponse> {
        return request.eventLoop.makeSucceededFuture(LKHTTPResponse(
            version: request.version,
            status: .ok,
            headers: [:],
            bodyStorage: .buffer(initialValue: self)
        ))
    }
}




public struct LKHTTPAbortError: Swift.Error, LKHTTPResponseConvertible {
    let status: HTTPResponseStatus
    let message: String?
    
    public init(status: HTTPResponseStatus, message: String? = nil) {
        self.status = status
        self.message = message
    }
    
    public func makeHTTPResponse(for request: LKHTTPRequest) -> EventLoopFuture<LKHTTPResponse> {
        return request.eventLoop.makeSucceededFuture(LKHTTPResponse(
            version: request.version,
            status: status,
            headers: [:],
            bodyStorage: .buffer(initialValue: message ?? "")
        ))
    }
}


