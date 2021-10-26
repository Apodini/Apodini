import Apodini
import ApodiniExtension
import ApodiniUtils
import ApodiniHTTPProtocol


public struct HTTPResponseTransformer<H: Handler>: ResultTransformer {
    private let encoder: AnyEncoder
    
    public init(_ encoder: AnyEncoder) {
        self.encoder = encoder
    }
    
    public func transform(input: Apodini.Response<H.Response.Content>) throws -> HTTPResponse {
        let body: ByteBuffer
        if let content = input.content {
            body = .init(data: try encoder.encode(content))
        } else {
            body = .init()
        }
        return HTTPResponse(
            version: input.information[HTTPRequest.InformationEntryHTTPVersion.Key.shared] ?? {
                // TODO we seem to be ending up here if this is a response created from an error thrown in a handler?
                print("UNEXPECTEDLY FOUND A NIL VALUE WHEN ATTEMPTING TO READ REQUEST HTTP VERSION. TODO FIX THIS THIS IS PROBABLY BAD [1]")
                return .http1_1 // just taking a guess idk
            }(),
            status: input.responseStatus,
            headers: HTTPHeaders(input.information),
            bodyStorage: .buffer(body)
        )
    }
    
    public func handle(error: ApodiniError) -> ErrorHandlingStrategy<HTTPResponse, ApodiniError> {
        .abort(error)
    }
}


public struct HTTPBlobResponseTransformer: ResultTransformer {
    public init() { }
    
    public func transform(input: Apodini.Response<Blob>) -> HTTPResponse {
        var body: ByteBuffer
        var information = input.information
        if let content = input.content {
            body = content.byteBuffer
            if let contentType = content.type?.description {
                information = information.merge(with: [AnyHTTPInformation(key: "Content-Type", rawValue: contentType)])
            }
        } else {
            body = .init()
        }
        return HTTPResponse(
            version: input.information[HTTPRequest.InformationEntryHTTPVersion.Key.shared] ?? {
                print("UNEXPECTEDLY FOUND A NIL VALUE WHEN ATTEMPTING TO READ REQUEST HTTP VERSION. TODO FIX THIS THIS IS PROBABLY BAD [2]")
                return .http1_1 // just taking a guess idk
            }(),
            status: input.responseStatus,
            headers: HTTPHeaders(information),
            bodyStorage: .buffer(body)
        )
    }
    
    public func handle(error: ApodiniError) -> ErrorHandlingStrategy<HTTPResponse, ApodiniError> {
        .abort(error)
    }
}


private extension Apodini.Response {
    var responseStatus: HTTPResponseStatus {
        switch self.status {
        case let .some(status):
            return HTTPResponseStatus(status)
        case .none:
            if self.content == nil {
                return .noContent
            } else {
                return .ok
            }
        }
    }
}
