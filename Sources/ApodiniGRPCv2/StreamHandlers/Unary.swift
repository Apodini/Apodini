import Apodini
import ApodiniExtension
import NIO
import NIOHPACK
import ApodiniUtils
import Foundation


class UnaryRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
    override func handle(message: GRPCv2MessageIn, context: GRPCv2StreamConnectionContext) -> EventLoopFuture<GRPCv2MessageOut> {
        let responseFuture: EventLoopFuture<Apodini.Response<H.Response.Content>> = decodingStrategy
            .decodeRequest(from: message, with: message, with: context.eventLoop)
            .insertDefaults(with: defaults)
            .cache()
            .evaluate(on: delegate)
        return responseFuture.map { (response: Apodini.Response<H.Response.Content>) -> GRPCv2MessageOut in
            let headers = HPACKHeaders {
                $0[.contentType] = .gRPC(.proto)
            }
            guard let responseContent = response.content else {
                return .singleMessage(headers: headers, payload: ByteBuffer(), closeStream: true)
            }
            return .singleMessage(
                headers: headers,
                payload: try! self.encodeResponseIntoProtoMessage(responseContent),
                closeStream: true
            )
        }
    }
}
