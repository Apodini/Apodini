import NIO

protocol AnyComponent {
    #warning("(Associated with Question 3.1) A protocol that Component confroms to that I use in the TupleComponent --> Question there")
}

protocol Component: AnyComponent {
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
