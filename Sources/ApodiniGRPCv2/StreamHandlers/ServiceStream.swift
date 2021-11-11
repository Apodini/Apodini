import Apodini
import ApodiniExtension
import NIO
import NIOHPACK
import Foundation


class ServiceSideStreamRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
    override func handle(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
        let responsesStream = GRPCv2MessageOut.Stream()
        let abortAnyError = AbortTransformer()
        return [message]
            .asAsyncSequence
            .decode(using: decodingStrategy, with: context.eventLoop)
            .insertDefaults(with: defaults)
            .cache()
            .subscribe(to: delegate)
            .evaluate(on: delegate)
            .transform(using: abortAnyError)
            .cancelIf { $0.connectionEffect == .close }
            .firstFutureAndForEach(
                on: context.eventLoop,
                objectsHandler: { (response: Apodini.Response<H.Response.Content>) -> Void in
//                    defer {
//                        if response.connectionEffect == .close {
//                            // TODO presumably this would get turned into an empty DATA frame (followed by the trailers)?
//                            // can we somehow skip the empty frame and directly translate this into sending trailers? (maybe by adding support for nil payloads?)
//                            responsesStream.writeAndClose((ByteBuffer(), closeStream: true))
//                        }
//                    }
                    do {
                        if let content = response.content {
//                            print("CONTENT: \(content)")
//                            let buffer = try! LKProtobufferEncoder().encode(content)
//                            print(buffer.lk_getAllBytes().description)
//                            try! ProtobufMessageLayoutDecoder.getFields(in: buffer).debugPrintFieldsInfo()
//                            if let decodableTy = H.Response.Content.self as? Decodable.Type {
//                                let decoder = _LKProtobufferDecoder(codingPath: [], buffer: buffer)
//                                let decoded = try! decodableTy.init(from: decoder)
//                                print("DECODED: \(decoded)")
//                            }
                            let buffer = try! self.encodeResponseIntoProtoMessage(content)
                            responsesStream.write((buffer, closeStream: response.connectionEffect == .close))
                        } else {
                            // TODO presumably this would get turned into an empty DATA frame (followed by the trailers)?
                            // can we somehow skip the empty frame and directly translate this into sending trailers? (maybe by adding support for nil payloads?)
                            responsesStream.write((ByteBuffer(), closeStream: response.connectionEffect == .close))
                        }
                    } catch {
                        // Error encoding the response data
                        fatalError("Error encoding part of response: \(error)")
                    }
                }
            )
            .map { firstResponse -> GRPCv2MessageOut in
                return GRPCv2MessageOut.stream(
                    HPACKHeaders {
                        $0[.contentType] = .gRPC(.proto)
                    },
                    responsesStream
                )
            }

    }
}
