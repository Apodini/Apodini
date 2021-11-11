import Foundation
import NIO
import NIOHPACK
import ApodiniNetworking
import ApodiniUtils


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


extension AnyHTTPHeaderName {
    // TODO move this to ApodiniNetworking!?!!
    static let pathPseudoHeader = HTTPHeaderName<String>(":path")
    static let statusPseudoHeader = HTTPHeaderName<HTTPResponseStatus>(":status")
}


extension HTTPResponseStatus: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        if let intValue = Int(value) {
            self.init(statusCode: intValue)
        } else {
            return nil
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        String(code)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(reasonPhrase)
    }
}


/// A stream-like object that will deliver its content to an observer closure, and buffer new content during the absence of such a closure.
class BufferedStream<Element> {
    typealias ObserverFn = (Element) -> Void
    
    private let lock = NSLock()
    private var buffer = CircularBuffer<Element>()
    private var observer: ObserverFn?
    private var isClosed = false
    
    init() {}
    
    func setObserver(_ observerFn: ObserverFn?) {
        lock.withLock {
            if let newObserver = observerFn {
                precondition(self.observer == nil, "Cannot set multiple observers on stream")
                for element in buffer {
                    newObserver(element)
                }
                buffer.removeAll()
                if !isClosed {
                    // Only actually set the observer if the stream is still open.
                    self.observer = newObserver
                }
            } else {
                self.observer = nil
            }
        }
    }
    
    func write(_ element: Element) {
        write(element, closeStream: false)
    }
    
    func writeAndClose(_ element: Element) {
        write(element, closeStream: true)
    }
    
    private func write(_ element: Element, closeStream: Bool) {
        lock.withLock {
            precondition(!isClosed, "Cannot write to closed stream")
            if let observer = observer {
                precondition(buffer.isEmpty) // If we have an observer, we expect the buffer to be empty
                observer(element)
            } else {
                buffer.append(element)
            }
            if closeStream {
                self.isClosed = true
                self.observer = nil
            }
        }
    }
}
