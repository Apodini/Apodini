import Apodini
import ApodiniExtension
import NIO
import NIOHPACK
import ApodiniUtils
import Foundation
@testable import ProtobufferCoding


class UnaryRPCHandler<H: Handler>: StreamRPCHandlerBase<H> {
    override func handle(message: GRPCMessageIn, context: GRPCStreamConnectionContext) -> EventLoopFuture<GRPCMessageOut> {
        let responseFuture: EventLoopFuture<Apodini.Response<H.Response.Content>> = decodingStrategy
            .decodeRequest(from: message, with: message, with: context.eventLoop)
            .insertDefaults(with: defaults)
            .cache()
            .evaluate(on: delegate)
        return responseFuture.map { (response: Apodini.Response<H.Response.Content>) -> GRPCMessageOut in
            let headers = HPACKHeaders {
                $0[.contentType] = .gRPC(.proto)
            }
            guard let responseContent = response.content else {
                return .singleMessage(headers: headers, payload: ByteBuffer(), closeStream: true)
            }
            // TODO remove!
//            if context.grpcMethodName.contains("GetAnInt") {
//                print(responseContent, type(of: responseContent))
//                let encoded = try! self.encodeResponseIntoProtoMessage(responseContent)
//                print(encoded.lk_getAllBytes())
//                try! ProtobufMessageLayoutDecoder.getFields(in: encoded).debugPrintFieldsInfo()
//                fatalError()
//            }
            return .singleMessage(
                headers: headers,
                payload: try! self.encodeResponseIntoProtoMessage(responseContent),
                closeStream: true
            )
        }
    }
}