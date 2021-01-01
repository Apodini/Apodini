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
                                                eventLoop: eventLoop,
                                                promise: promise,
                                                responseModifiers: self.endpoint.responseTransformers)

                    switch response {
                    case let apodiniEncodableResponse as EncodableContainer:
                        // is an Action; use visitor to access wrapped element
                        apodiniEncodableResponse.accept(visitor)
                    default:
                        // not an action; wrap it into an action
                        let action: Action<H.Response> = .final(response)
                        action.accept(visitor)
                    }
                    return promise.futureResult
                }
            }
    }
}

struct ActionVisitor: EncodableContainerVisitor {
    let request: Request

    let eventLoop: EventLoop
    let promise: EventLoopPromise<Action<AnyEncodable>>

    let responseModifiers: [() -> (AnyResponseTransformer)]

    func visit<Value: Encodable>(_ action: Action<Value>) {
        if Value.self is EncodableContainer.Type {
            fatalError("Action cannot contain a encodable container: \(Value.self)")
        }

        switch action {
        case let .send(element):
            transformResponse(element)
                    .map { result in
                        .send(result)
                    }
                    .cascade(to: promise)
        case let .final(element):
            transformResponse(element)
                    .map { result in
                        .final(result)
                    }
                    .cascade(to: promise)
        case .nothing:
            // no response to run through the responseModifiers
            promise.succeed(.nothing)
        case .end:
            // no response to run through the responseModifiers
            promise.succeed(.end)
        }
    }

    func transformResponse(_ response: Encodable) -> EventLoopFuture<AnyEncodable> {
        let responseFuture = eventLoop.wrapEncodableIntoFuture(encodable: response)
        return transformNextResponse(responseFuture, responseModifiers)
                .map { encodable in
                    AnyEncodable(value: encodable)
                }
    }

    func transformNextResponse(_ response: EventLoopFuture<Encodable>, _ modifiers: [() -> (AnyResponseTransformer)]) -> EventLoopFuture<Encodable> {
        if modifiers.isEmpty {
            return response
        }

        var modifiers = modifiers
        let next = modifiers.removeFirst()

        return response.flatMap { encodable in
            let transformed = request.enterRequestContext(with: next()) { responseTransformer in
                responseTransformer.transform(response: encodable)
            }
            let responseFuture = eventLoop.wrapEncodableIntoFuture(encodable: transformed)
            return transformNextResponse(responseFuture, modifiers)
        }
    }
}

// MARK: Apodini Encodable Value
extension EventLoop {
    func wrapEncodableIntoFuture(encodable: Encodable) -> EventLoopFuture<Encodable> {
        if encodable is EncodableContainer {
            fatalError("Can't wrap an encodable container of type \(type(of: encodable)) into EventLoopFuture")
        }

        if let apodiniEncodable = encodable as? EncodableValue {
            let visitor = EventLoopFutureUnwrapper()
            return apodiniEncodable.accept(visitor)
        } else {
            return makeSucceededFuture(encodable)
        }
    }
}

private struct EventLoopFutureUnwrapper: EncodableValueVisitor {
    func visit<Value: Encodable>(_ future: EventLoopFuture<Value>) -> EventLoopFuture<Encodable> {
        if Value.self is EncodableContainer.Type {
            fatalError("EventLoopFuture cannot contain a encodable container: \(Value.self)")
        }

        if Value.self is EncodableValue.Type {
            // unwrap futures containing futures
            return future.flatMap { result in
                // swiftlint:disable:next force_cast
                let encodableValue = result as! EncodableValue // we check above if this cast is possible
                return encodableValue.accept(self)
            }
        } else {
            // swiftlint:disable:next array_init
            return future.map { $0 }
        }
    }
}
