import Apodini
import ApodiniNetworking


enum GRPCv2MessageEncoding: String {
    case proto
    case json
}


// Note: the fact that it exists, and that we could recognise it, does not mean that we support it
enum GRPCv2MessageCompressionType: RawRepresentable, HTTPHeaderFieldValueCodable {
    case identity
    case gzip
    case deflate
    case snappy
    case custom(String)
    
    init(rawValue: String) {
        switch rawValue {
        case Self.identity.rawValue:
            self = .identity
        case Self.gzip.rawValue:
            self = .gzip
        case Self.deflate.rawValue:
            self = .deflate
        case Self.snappy.rawValue:
            self = .snappy
        default:
            self = .custom(rawValue)
        }
    }
    
    init(httpHeaderFieldValue value: String) {
        self.init(rawValue: value)
    }
    
    func encodeToHTTPHeaderFieldValue() -> String {
        rawValue
    }
    
    var rawValue: String {
        switch self {
        case .identity:
            return "identity"
        case .gzip:
            return "gzip"
        case .deflate:
            return "deflate"
        case .snappy:
            return "snappy"
        case .custom(let value):
            return value
        }
    }
}



extension AnyHTTPHeaderName {
    static let gRPCEncoding = HTTPHeaderName<GRPCv2MessageCompressionType>("grpc-encoding")
}



struct GRPCv2HTTPResponder<H: Handler>: HTTPResponder {
    let endpoint: Endpoint<H>
    
    func respond(to request: HTTPRequest) -> HTTPResponseConvertible {
        // TODO enforce http2?? is that actually something we notice here? or does NIO abstract all of that away?
        guard
            let contentType = request.headers[.contentType],
            contentType.equalsIgnoringSuffix(.gRPC)
        else {
            return HTTPResponse(version: request.version, status: .unsupportedMediaType, headers: [:])
        }
        
        let messageEncoding: GRPCv2MessageEncoding
        if let suffix = contentType.suffix {
            if let encoding = GRPCv2MessageEncoding(rawValue: suffix) {
                messageEncoding = encoding
            } else {
                return HTTPResponse(version: request.version, status: .unsupportedMediaType, headers: [:])
            }
        } else {
            // If the content type header does not specify an encoding via the suffix, we assume protobuffers as the default
            messageEncoding = .proto
        }
        
        // TODO is .gzip the correct default here?
        //let messageCompressionType = request.headers[commaSeparated: .gRPCEncoding].map { GRPCv2MessageCompressionType(rawValue: $0) } ?? .gzip
        //let messageCompressionType = request.headers[singleValue: .gRPCEncoding, as: GRPCv2MessageCompressionType.self] ?? .gzip
        let messageCompressionType = request.headers[.gRPCEncoding] ?? .gzip
        
        
        fatalError("TODO")
    }
}



class GRPCv2Message {
    // TODO
}



extension GRPCv2Message: HTTPResponseConvertible {
    func makeHTTPResponse(for request: HTTPRequest) -> EventLoopFuture<HTTPResponse> {
        return request.eventLoop.makeFailedFuture(GRPCv2Error(message: "Not Yet Implemented"))
//        let response = HTTPResponse(
//            version: request.version,
//            status: .ok,
//            headers: .init([
//                (.gRPCEncoding, GRPCv2MessageCompressionType.gzip)
//            ]),
//            body: <#T##ByteBuffer#>
//        )
//        return request.eventLoop.makeSucceededFuture(<#T##value: Success##Success#>)
    }
}
