import NIO

extension Never: Component {
    var content: Never {
        fatalError("Never Type has no body")
    }
    
    func handle(_ request: Request) -> EventLoopFuture<Never> {
        request.eventLoop.makeFailedFuture(HTTPError.notImplemented)
    }
}

extension Never: Codable {
    public init(from decoder: Decoder) throws {
        fatalError("Never should never be decoded")
    }
    
    public func encode(to encoder: Encoder) throws {
        fatalError("Never should never be encoded")
    }
}

extension Component where Content == Never {
    var content: Never {
        fatalError("\(type(of: self)) has no body")
    }
}

extension Component where Response == Never {
    func handle(_ request: Request) -> EventLoopFuture<Never> {
        request.eventLoop.makeFailedFuture(HTTPError.notImplemented)
    }
}

struct EmptyComponent: Component {
    typealias Content = Never
    typealias Response = Never
}
