//
// Created by Andi on 25.12.20.
//

import class NIO.EventLoopFuture
import protocol NIO.EventLoop
import protocol FluentKit.Database
import struct NIO.EventLoopPromise

class EndpointRequestHandler<I: InterfaceExporter> {
    func callAsFunction(request: I.ExporterRequest, eventLoop: EventLoop) -> EventLoopFuture<Action<AnyEncodable>> {
        // We are doing nothing here. Everything is handled in InternalEndpointRequestHandler
        fatalError("EndpointRequestHandler.handleRequest() was not overridden. EndpointRequestHandler must not be created manually!")
    }
}

extension EndpointRequestHandler where I.ExporterRequest: WithEventLoop {
    func callAsFunction(request: I.ExporterRequest) -> EventLoopFuture<Action<AnyEncodable>> {
        callAsFunction(request: request, eventLoop: request.eventLoop)
    }
}

class InternalEndpointRequestHandler<I: InterfaceExporter, H: Handler>: EndpointRequestHandler<I> {
    private var endpoint: Endpoint<H>
    private var exporter: I

    init(endpoint: Endpoint<H>, exporter: I) {
        self.endpoint = endpoint
        self.exporter = exporter
    }

    override func callAsFunction(request exporterRequest: I.ExporterRequest, eventLoop: EventLoop) -> EventLoopFuture<Action<AnyEncodable>> {
        let request = ApodiniRequest(for: exporter, with: exporterRequest, on: endpoint, running: eventLoop)

        let guardEventLoopFutures = endpoint.guards.map { guardClosure in
            request.enterRequestContext(with: guardClosure()) { requestGuard in
                requestGuard.executeGuardCheck(on: request)
            }
        }

        return EventLoopFuture<Void>
            .whenAllSucceed(guardEventLoopFutures, on: eventLoop)
            .flatMap { _ in
                request.enterRequestContext(with: self.endpoint.handler) { handler in
                    let response = handler.handle()
                    let promise = request.eventLoop.makePromise(of: Action<AnyEncodable>.self)
                    let visitor = ActionVisitor(request: request,
                                                promise: promise,
                                                responseModifiers: self.endpoint.responseTransformers)
                    switch response {
                    case let apodiniEncodableResponse as ApodiniEncodable:
                        // is an Action
                        // use visitor to access
                        // wrapped element
                        apodiniEncodableResponse.accept(visitor)
                    default:
                        // not an action
                        // we can skip the visitor
                        visitor.visit(encodable: response)
                    }
                    return promise.futureResult
                }
            }
    }
}

struct ActionVisitor: ApodiniEncodableVisitor {
    let request: Request
    let promise: EventLoopPromise<Action<AnyEncodable>>
    let responseModifiers: [() -> (AnyResponseTransformer)]

    func visit<Element: Encodable>(encodable: Element) {
        let result = transformResponse(encodable)
        promise.succeed(.final(result))
    }

    func visit<Element: Encodable>(action: Action<Element>) {
        switch action {
        case let .send(element):
            let result = transformResponse(element)
            promise.succeed(.send(result))
        case let .final(element):
            let result = transformResponse(element)
            promise.succeed(.final(result))
        case .nothing:
            // no response to run through the responseModifiers
            promise.succeed(.nothing)
        case .end:
            // no response to run through the responseModifiers
            promise.succeed(.end)
        }
    }

    func transformResponse(_ response: Encodable) -> AnyEncodable {
        var response = response
        for responseTransformer in responseModifiers {
            response = request.enterRequestContext(with: responseTransformer()) { responseTransformer in
                responseTransformer.transform(response: response)
            }
        }
        return AnyEncodable(value: response)
    }
}
