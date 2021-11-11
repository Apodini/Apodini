import Foundation
import Apodini
import ApodiniExtension
import NIO
import NIOHPACK


struct GRPCv2MessageIn: RequestBasis, CustomStringConvertible, CustomDebugStringConvertible {
    let remoteAddress: SocketAddress?
    /// The HTTP/2 headers sent with the initial HTTP request that initiated this stream
    let requestHeaders: HPACKHeaders
    /// The payload of this message
    let payload: ByteBuffer
    
    var targetServiceName: String {
        String(requestHeaders[.pathPseudoHeader]!.split(separator: "/")[0])
    }
    
    var targetMethodName: String {
        String(requestHeaders[.pathPseudoHeader]!.split(separator: "/")[1])
    }
    
    var serviceAndMethodName: (service: String, method: String) {
        let splitPath = requestHeaders[.pathPseudoHeader]!.split(separator: "/")
        return (String(splitPath[0]), String(splitPath[1]))
    }
    
    var description: String {
        ///"\(Self.self)(headers: \()"
        var retval = "\(Self.self)("
        retval.append("headers: ")
        retval.append("\(requestHeaders.map { "\($0.name)=\($0.value)" })")
        retval.append(", payload: \(payload)")
        retval.append(")")
        return retval
    }
    
    var debugDescription: String {
        description
    }
    
    var information: InformationSet {
        [] // TODO?
    }
}


/// The result of an RPC invocation.
/// Note that the differentiation here between `singleMessage` and `stream` is not necessarily equivalent to gRPC's differentiation between unary and stream-based methods.
/// `singleMessage` is intended for situations where a call results in one response message, regardless of whether or not the connection is to be kept open or closed.
/// (e.g.: unary connections, bidirectional connections where every client request gets answered with exactly one server response, etc.)
/// `stream` is intended for situations where a single client request may result in multiple responses.
enum GRPCv2MessageOut {
    typealias Stream = BufferedStream<(ByteBuffer, closeStream: Bool)>
    /// A single gRPC message.
    /// - parameter headers: The headers to be sent with this message. Note that headers will only be written once to a HTTP/2 stream.
    /// - parameter payload: The gRPC message data to be written.
    /// - parameter closeStream: Whether after sending this message, the connection to the client (i.e. the underlying HTTP/2 stream) should be closed.
    case singleMessage(headers: HPACKHeaders, payload: ByteBuffer, closeStream: Bool)
    /// A RPC resulted in a stream-based response.
    case stream(HPACKHeaders, Stream)
    
    var headers: HPACKHeaders {
        switch self {
        case .singleMessage(let headers, _, _), .stream(let headers, _):
            return headers
        }
    }
}
