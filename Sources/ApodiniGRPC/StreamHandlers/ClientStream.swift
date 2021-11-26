import Apodini
import ApodiniExtension
import NIO
import NIOHPACK
import Foundation



extension EventLoopFuture {
    //func mapAlways<NewValue>(_ callback: @escaping (Result<Value, Error> -> NewValue)
}



class ClientSideStreamRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
    override func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
        print("[\(Self.self)] \(#function)")
        let abortAnyError = AbortTransformer()
        let headers = HPACKHeaders {
            $0[.contentType] = .gRPC(.proto)
        }
        return [message]
            .asAsyncSequence
            .decode(using: decodingStrategy, with: context.eventLoop)
            .insertDefaults(with: defaults)
            .cache()
            .subscribe(to: delegate)
            .evaluate(on: delegate)
            .transform(using: abortAnyError)
            .cancelIf { $0.connectionEffect == .close }
            .firstFuture(on: context.eventLoop)
            .flatMapAlways { (result: Result<Apodini.Response<H.Response.Content>?, Error>) -> EventLoopFuture<GRPCMessageOut> in
                switch result {
                case .failure(let error):
                    fatalError("\(error)") // TODO when do we end up here? are these errors thrown in handlers?
                case .success(.none):
                    fatalError("???the sequence was empty???")
                case .success(.some(let response)):
                    if response.isNothing {
                        // The handler returned a `.nothing` response, indicating to us that the connection should be kept open and a response will be sent with a future client request
                        return context.eventLoop.makeSucceededFuture(.nothing(headers))
                    } else {
                        guard let responseContent = response.content else {
                            // TODO. Important question. What semantics do we want for client-streaming RPC handlers?
                            // The way this should end up working is that the client can send as many requests as they want, and the first "non-nothing"
                            // response from the handler will ter,inate the call.
                            // Quesrion: do we accept only `.nothing` resopnses as "keep the stream open" responses, or also empty responses.
                            // What if the handler intentionally wants to end the stream w/ an empty response?
                            return context.eventLoop.makeSucceededFuture(.singleMessage(
                                headers: headers,
                                payload: ByteBuffer(),
                                closeStream: true
                            ))
                        }
                        return context.eventLoop.makeSucceededFuture(.singleMessage(
                            headers: headers,
                            payload: try! self.encodeResponseIntoProtoMessage(responseContent), // TODO have this just terminate the stream, instead of terminating all of Apodini?
                            closeStream: true
                        ))
                    }
                }
            }
    }
}
