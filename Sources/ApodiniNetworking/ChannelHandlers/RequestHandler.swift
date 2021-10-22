import NIO
import NIOHTTP1
import NIOWebSocket
import WebSocketKit
import Foundation


class HTTPServerRequestHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = HTTPRequest
    typealias OutboundOut = HTTPResponse
    
    private let responder: HTTPResponder // TODO does this introduce a retain cycle?? (we're passing the server here, which holds a reference to the channel, to the pipeline of which this handler is added!!!!
    
    init(responder: HTTPResponder) {
        self.responder = responder
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let request = unwrapInboundIn(data)
        responder
            .respond(to: request)
            .makeHTTPResponse(for: request)
            .hop(to: context.eventLoop)
            .whenComplete { (result: Result<HTTPResponse, Error>) in
                switch result {
                case .failure(let error):
                    // NOTE: if we get an error here, that error is _NOT_ coming from the route's handler (since these error already got mapped into .internalServerError http responses previously in the chain...)
                    fatalError("Unexpectedly got a failed future: \(error)")
                case .success(let httpResponse):
                    switch httpResponse.bodyStorage {
                    case .buffer:
                        self.handleResponse(httpResponse, context: context)
                    case .stream(let stream):
                        stream.setObserver { stream, event in
                            context.eventLoop.execute {
                                self.handleResponse(httpResponse, context: context)
                            }
                        }
                        self.handleResponse(httpResponse, context: context)
                    }
                }
        }
    }
    
    
    private func handleResponse(_ response: HTTPResponse, context: ChannelHandlerContext) {
        response.headers.setUnlessPresent(name: .date, value: Date()) // TODO do we really want to do this here?
        // TODO use thus to log errors/warning if responses are lacking certain headers (and then also move the header adjustments elsewhere!)
        context.write(self.wrapOutboundOut(response)).whenComplete { result in
            switch result {
            case .success:
                // TODO check whether or not to keep the thing alive!
                let keepAlive: Bool = false // If this is true, the channel will always be kept open. otherwise, it might be if it's a stream
                switch response.bodyStorage {
                case .buffer:
                    if !keepAlive {
                        context.close(mode: .output, promise: nil)
                    }
                case .stream(let stream):
                    if !keepAlive && stream.isClosed {
                        context.close(mode: .output, promise: nil)
                    }
                }
            case .failure(let error):
                self.errorCaught(context: context, error: error)
            }
        }
    }
    
    // TODO what if were removed while waiting on some stream?
//    func removeHandler(context: ChannelHandlerContext, removalToken: ChannelHandlerContext.RemovalToken) {
//        <#code#>
//    }
}


//class WebSocketsRequestHandler: ChannelInboundHandler {
//    typealias InboundIn = WebSocketFrame
//    typealias OutboundOut = WebSocketFrame
//
//    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
//        fatalError("TODO")
//    }
//}