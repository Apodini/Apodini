import NIO
import NIOHTTP1


class HTTPServerRequestDecoder: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias InboundOut = HTTPRequest
    
    private enum State {
        case ready
        case awaitingBody(HTTPRequest)
        //case readingStream(HTTPRequest) // TODO!!!!
        case awaitingEnd(HTTPRequest)
    }
    
    private var state: State = .ready
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let request = unwrapInboundIn(data)
        switch (state, request) {
        case (.ready, .head(let reqHead)):
            guard let url = URI(string: reqHead.uri) else {
                fatalError("received invalid url: '\(reqHead.uri)'")
            }
            let request = HTTPRequest(
                remoteAddress: context.channel.remoteAddress,
                version: reqHead.version,
                method: reqHead.method,
                url: url,
                headers: reqHead.headers,
                bodyStorage: .buffer(),
                eventLoop: context.eventLoop
            )
            state = .awaitingBody(request)
        case (.ready, .body):
            fatalError("Invalid state: received unexpected body (was waiting for head)")
        case (.ready, .end):
            fatalError("Invalid state: received unexpected end (was waiting for head)")
        case (.awaitingBody, .head(_)):
            fatalError("Invalid state: received unexpected head (was waiting for body)")
        case (.awaitingBody(let req), .body(let bodyBuffer)):
            print("Awaiting Body. Received Body. Body: \(bodyBuffer)")
            if req.headers[.contentLength] == bodyBuffer.readableBytes {
            //if req.headers.first(name: .contentLength).map(Int.init) == bodyBuffer.readableBytes {
                req.bodyStorage = .buffer(bodyBuffer)
                state = .awaitingEnd(req)
            } else {
                //req.bodyStorage = .stream(<#T##LKDataStream#>) // TODO
                fatalError("TODO: implement") // NOTE: it's weird (i.e. bad) that none of the tests end up in this branch
            }
        case (.awaitingBody(let req), .end(let endHeaders)):
            //fatalError("Invalid state: received unexpected end (was waiting for body)")
            print("Awaiting Body. Got End.", req, endHeaders)
            context.fireChannelRead(wrapInboundOut(req))
            state = .ready
            break
        case (.awaitingEnd, .head):
            fatalError("Invalid state: received unexpected head (was waiting for end)")
        case (.awaitingEnd, .body):
            fatalError("Invalid state: received unexpected body (was waiting for end)")
        case (.awaitingEnd(let req), .end(let endHeaders)):
            print("Awaiting End. Got End.", req, endHeaders)
            context.fireChannelRead(wrapInboundOut(req))
            state = .ready
        }
    }
}
