import NIO

protocol RequestInjectable {
    func inject(using request: Request) throws
    func disconnect()
}

struct Request {
    let httpType: HTTPType
    let headers: [String: String]
    let body: ByteBuffer
    let context: Context
    
    
    var eventLoop: EventLoop {
        context.eventLoop
    }
    
    
    init(httpType: HTTPType = .get,
         headers: [String: String] = [:],
         body: ByteBuffer = ByteBuffer(),
         context: Context) {
        self.httpType = httpType
        self.headers = headers
        self.body = body
        self.context = context
    }
    
    
    func executeInContext<C: Component>(_ component: C) -> EventLoopFuture<C.Response> {
        let viewMirror = Mirror(reflecting: component)
        
        defer {
            for child in viewMirror.children {
                if let anyCurrentDatabase = child.value as? RequestInjectable {
                    anyCurrentDatabase.disconnect()
                }
            }
        }
        
        // Inject all properties that can be injected using RequestInjectable
        for child in viewMirror.children {
            if let anyCurrentDatabase = child.value as? RequestInjectable {
                do {
                    try anyCurrentDatabase.inject(using: self)
                } catch {
                    return context.eventLoop.makeFailedFuture(error)
                }
            }
        }
        
        return component.handle(self)
    }
}
