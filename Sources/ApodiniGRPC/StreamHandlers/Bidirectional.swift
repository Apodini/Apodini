import Apodini
import ApodiniExtension
import NIO
import NIOHPACK
import Foundation


// TODO this needs a rework (as does the HTTP IE's bidirectional stream handling), to add proper support for streams other than client req -> server res.
// The problem is that e.g. it currently isn't really possible to respond to one client request w/ multiple separate responses.
// Why? 1. There is no way for the handler to return twice, you'd have to use like the ObservedObject stuff to get that working.
// But even then there's really no good way for the handler to differentiate between getting called for a proper message or for one of these observed object calls.
// Also, the NIO channel handler calling the handler will somehow need to know about the fact that the handler is currently still busy, so that it can wait with handling new incoming requests until the handler is done handling the current one.
class BidirectionalStreamRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
    override func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
        let headers = HPACKHeaders {
            $0[.contentType] = .gRPC(.proto)
        }
        let abortAnyError = AbortTransformer()
        let retFuture: EventLoopFuture<GRPCMessageOut> = [message]
            .asAsyncSequence
            .decode(using: decodingStrategy, with: context.eventLoop)
            .insertDefaults(with: defaults)
            .cache()
            .subscribe(to: delegate)
            .evaluate(on: delegate)
            .transform(using: abortAnyError)
            .cancelIf { $0.connectionEffect == .close }
            .firstFuture(on: context.eventLoop)
            .map { (response: Response<H.Response.Content>?) -> GRPCMessageOut in
                guard let response = response else {
                    fatalError() // TODO!
                }
                if response.isNothing {
                    return .nothing(headers)
                } else if let content = response.content {
                    return .singleMessage(
                        headers: headers,
                        payload: try! self.encodeResponseIntoProtoMessage(content),
                        closeStream: response.connectionEffect == .close
                    )
                } else {
                    // We got a response which is not .nothing, but also doesn't contain any content. Do we still want to send a message back to the client?
                    return .singleMessage(headers: headers, payload: ByteBuffer(), closeStream: response.connectionEffect == .close)
                }
            }
//            .flatMapAlways { (result: Result<Response<H.Response.Content>?, Error>) -> EventLoopFuture<GRPCMessageOut> in
//                switch result {
//                case .failure(let error):
//
//                }
//            }
//            .firstFutureAndForEach(
//                on: context.eventLoop,
//                objectsHandler: { (response: Apodini.Response<H.Response.Content>) -> Void in
//                    guard !response.isNothing else {
//                        return
//                    }
//                    do {
//                        if let content = response.content {
//                            let buffer = try self.encodeResponseIntoProtoMessage(content)
//                            self.responsesStream.write((buffer, closeStream: response.connectionEffect == .close))
//                        } else {
//                            // TODO presumably this would get turned into an empty DATA frame (followed by the trailers)?
//                            // can we somehow skip the empty frame and directly translate this into sending trailers? (maybe by adding support for nil payloads?)
//                            self.responsesStream.write((ByteBuffer(), closeStream: response.connectionEffect == .close))
//                        }
//                    } catch {
//                        // Error encoding the response data
//                        fatalError("Error encoding part of response: \(error)")
//                    }
//                }
//            )
//            .map { firstResponse -> GRPCMessageOut in
//                if shouldReturnStreamOpen {
//                    return GRPCMessageOut.stream(
//                        HPACKHeaders {
//                            $0[.contentType] = .gRPC(.proto)
//                        },
//                        self.responsesStream
//                    )
//                } else {
//                    return .nothing([:])
//                }
//            }
        //retFuture.whenComplete { _ in
            //print("message handler returned. id: \(id)")
        //}
        return retFuture
    }
}


//class BidirectionalStreamRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
//    private let responsesStream = GRPCMessageOut.Stream()
//    /// Whether the RPC handler already sent its initial "open stream" response.
//    private var didSendInitialStreamOpen = false
//
//    override func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
//        // TODO one potential problem here is that we might end up in a situation where this function gets called a second time (i.e. for a second incoming message) while the first request is still being processed (eg by writing to a stream).
//        // The reason for this is that, if there's multiple messages queued up, the next one will be handled (i.e. sent to this method) when the previous message's response future completes. But in the case of streams, we send a completed future even though more data will be written to the stream later on...
//        let shouldReturnStreamOpen = !self.didSendInitialStreamOpen
//        self.didSendInitialStreamOpen = true
//
//        let abortAnyError = AbortTransformer()
//        let retFuture = [message]
//            .asAsyncSequence
//            .decode(using: decodingStrategy, with: context.eventLoop)
//            .insertDefaults(with: defaults)
//            .cache()
//            .subscribe(to: delegate)
//            .evaluate(on: delegate)
//            .transform(using: abortAnyError)
//            .cancelIf { $0.connectionEffect == .close }
//            .firstFutureAndForEach(
//                on: context.eventLoop,
//                objectsHandler: { (response: Apodini.Response<H.Response.Content>) -> Void in
//                    guard !response.isNothing else {
//                        return
//                    }
//                    do {
//                        if let content = response.content {
//                            let buffer = try self.encodeResponseIntoProtoMessage(content)
//                            self.responsesStream.write((buffer, closeStream: response.connectionEffect == .close))
//                        } else {
//                            // TODO presumably this would get turned into an empty DATA frame (followed by the trailers)?
//                            // can we somehow skip the empty frame and directly translate this into sending trailers? (maybe by adding support for nil payloads?)
//                            self.responsesStream.write((ByteBuffer(), closeStream: response.connectionEffect == .close))
//                        }
//                    } catch {
//                        // Error encoding the response data
//                        fatalError("Error encoding part of response: \(error)")
//                    }
//                }
//            )
//            .map { firstResponse -> GRPCMessageOut in
//                if shouldReturnStreamOpen {
//                    return GRPCMessageOut.stream(
//                        HPACKHeaders {
//                            $0[.contentType] = .gRPC(.proto)
//                        },
//                        self.responsesStream
//                    )
//                } else {
//                    return .nothing([:])
//                }
//            }
//        //retFuture.whenComplete { _ in
//            //print("message handler returned. id: \(id)")
//        //}
//        return retFuture
//    }
//}
