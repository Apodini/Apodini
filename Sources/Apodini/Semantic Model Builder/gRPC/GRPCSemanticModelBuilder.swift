//
//  GRPCSemanticModelBuilder.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

@_implementationOnly import Vapor
import protocol Fluent.Database

struct GRPCRequest: Request {
    private var parameterDecoder: (UUID) -> Codable?
    var eventLoop: EventLoop
    var description: String
    var database: Fluent.Database?
    private var wrappedRequest: Vapor.Request

    init(_ vaporRequest: Vapor.Request, parameterDecoder: @escaping (UUID) -> Codable?) {
        self.eventLoop = vaporRequest.eventLoop
        self.database = nil
        self.parameterDecoder = parameterDecoder
        self.description = vaporRequest.description
        self.wrappedRequest = vaporRequest
    }

    func parameter<T: Codable>(for parameter: UUID) throws -> T? {
        return parameterDecoder(parameter) as? T
    }

    var body: Vapor.Request.Body {
        wrappedRequest.body
    }
}

class GRPCSemanticModelBuilder: SemanticModelBuilder {
    override func register<C: Component>(component: C, withContext context: Context) {
        let handler: (GRPCRequest) -> EventLoopFuture<Encodable> =
            createClientStreamRequestHandler(for: component, with: context)
        app.on(.POST, "testservice", "method", body: .stream, use: { request -> EventLoopFuture<Vapor.Response> in
            let grpcRequest = GRPCRequest(request, parameterDecoder: { uuid in return nil })
            let response: EventLoopFuture<Encodable> = handler(grpcRequest)

            let result = response.flatMapThrowing { (response: Encodable) -> Vapor.Response in
                let data = try JSONEncoder().encode(AnyEncodable(value: response))
                return Vapor.Response(body: .init(data: data))
            }

            return result
        })
    }

    private func processGuards(_ request: Request, with context: Context) -> [EventLoopFuture<Void>] {
        return context.get(valueFor: GuardContextKey.self)
            .map { requestGuard in
                request.enterRequestContext(with: requestGuard()) { requestGuard in
                    requestGuard.executeGuardCheck(on: request)
                }
            }
    }

    /// Used by the GRPCSemanticModelBuilder to export client-side streaming endpoints.
    func createClientStreamRequestHandler<C: Component>(for component: C, with context: Context)
    -> (GRPCRequest) -> EventLoopFuture<Encodable> {
        { (request: GRPCRequest) in
            let resultPromise = request.eventLoop.makePromise(of: Encodable.self)
            request.body.drain { (bodyStream: BodyStreamResult) in
                let con: Connection
                switch bodyStream {
                case let .buffer(byteBuffer):
                    con = Connection(state: .open)
                    #if DEBUG
                    if let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes) {
                        print("\([UInt8](data))")
                    }
                    #endif
                    // TODO check data for completenes (using length-info at beginning)
                    // & collect multiple frames if necessary
                    // cite: https://grpc.io/blog/grpc-on-http2/
                    // "RPCs are in practice plain HTTP/2 streams.
                    // Messages are associated with RPCs and get sent as HTTP/2 data frames.
                    // To be more specific, messages are layered on top of data frames.
                    // A data frame may have many gRPC messages,
                    // or if a gRPC message is quite large it might span multiple data frames."
                case .end:
                    con = Connection(state: .end)
                case let .error(error):
                    return request.eventLoop.makeFailedFuture(error)
                }

                let guardEventLoopFutures = self.processGuards(request, with: context)
                return EventLoopFuture<Void>
                    .whenAllSucceed(guardEventLoopFutures, on: request.eventLoop)
                    .flatMap { _ in
                        request.enterRequestContext(with: component) { component in
                            let response: Action<C.Response> = component
                                .handle()
                            switch response {
                            case let .send(element),
                                 let .final(element):
                                var encodable: Encodable = element
                                for responseTransformer in context.get(valueFor: ResponseContextKey.self) {
                                    encodable = request.enterRequestContext(with: responseTransformer()) { responseTransformer in
                                        responseTransformer.transform(response: encodable)
                                    }
                                }

                                let response = request.eventLoop.makeSucceededFuture(encodable)
                                resultPromise.completeWith(response)
                            default: // .nothing
                                // we do nothing 😆
                                break
                            }
                            return request.eventLoop.makeSucceededFuture(())
                        }
                    }
            }
            return resultPromise.futureResult
        }
    }
}
