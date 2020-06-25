import NIO


protocol Component {
    associatedtype Content: Component
    associatedtype Response: Codable
    
    var content: Content { get }
    
    func handle(_ request: Request) -> EventLoopFuture<Response>
}

extension Component {
    func executeInContext(of request: Request) -> EventLoopFuture<Response> {
        request.executeInContext(self)
    }
}
