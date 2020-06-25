import NIO


protocol Component {
    associatedtype Content: Component
    associatedtype Response: Codable
    
    var content: Content { get }
    
    func handle(_ request: Request) -> EventLoopFuture<Response>
}
