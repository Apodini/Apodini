import NIO


struct Text: Component {
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    func handle(_ request: Request) -> EventLoopFuture<String> {
        request.eventLoop.makeSucceededFuture(text)
    }
}
