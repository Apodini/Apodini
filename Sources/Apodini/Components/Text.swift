import NIO


struct Text: Component {
    private let text: String
    
    
    init(_ text: String) {
        self.text = text
    }
    
    
    func handle(_ request: Request) -> EventLoopFuture<String> {
        request.eventLoop.makeSucceededFuture(text)
    }
    
    func visit<V>(_ visitor: inout V) where V : Visitor {
        visitor.register(self)
    }
}

//extension Component {
//    func fontSize(_ size: Int) -> some Component {
//        FontSizeComponent(content: self)
//    }
//}
//
//struct FontSizeModifier<Content: Component>: Component {
//    var content: Component
//    func handle(_ request: Request) -> ... {
//        ...
//    }
//}
