import NIO


struct Request {
    let httpType: HTTPType
    let headers: [String: String]
    let body: ByteBuffer
    let eventLoop: EventLoop
    
    init() {
        fatalError("Not implmented")
    }
}
