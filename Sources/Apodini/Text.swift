import NIO


struct Text: Component {
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    // Question: I am not 100% sure why there are default implementations for content and the handle method here. Is the associated type defaulted to Never if I don't implicityl define it?
    
    func handle(_ request: Request) -> EventLoopFuture<String> {
        request.eventLoop.makeSucceededFuture(text)
    }
}
