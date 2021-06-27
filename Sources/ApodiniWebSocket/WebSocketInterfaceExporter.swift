//
//  WebSocketInterfaceExporter.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Apodini
import ApodiniUtils
import ApodiniExtension
import ApodiniVaporSupport
import NIOWebSocket
@_implementationOnly import OpenCombine
@_implementationOnly import Vapor

// MARK: Exporter

public final class WebSocket: Configuration {
    let configuration: WebSocket.ExporterConfiguration
    
    public init(path: String = "apodini/websocket") {
        self.configuration = WebSocket.ExporterConfiguration(path: path)
    }
    
    public func configure(_ app: Apodini.Application) {
        /// Instanciate exporter
        let webSocketExporter = WebSocketInterfaceExporter(app, self.configuration)
        
        /// Insert exporter into `InterfaceExporterStorage`
        app.registerExporter(exporter: webSocketExporter)
    }
}

/// The WebSocket exporter uses a custom JSON based protocol on top of WebSocket's text messages.
/// This protocol can handle multiple concurrent connections on the same or different endpoints over one WebSocket channel.
/// The Apodini service listens on /apodini/websocket for clients that want to communicate via the WebSocket Interface Exporter.
final class WebSocketInterfaceExporter: InterfaceExporter {
    private let app: Apodini.Application
    private let exporterConfiguration: WebSocket.ExporterConfiguration
    private let router: VaporWSRouter

    /// Initalize a `WebSocketInterfaceExporter` from an `Application`
    init(_ app: Apodini.Application,
         _ exporterConfiguration: WebSocket.ExporterConfiguration = WebSocket.ExporterConfiguration()) {
        self.app = app
        self.exporterConfiguration = exporterConfiguration
        self.router = VaporWSRouter(app.vapor.app, logger: app.logger, at: self.exporterConfiguration.path)
    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        let inputParameters: [(name: String, value: InputParameter)] = endpoint.exportParameters(on: self).map { parameter in
            (name: parameter.0, value: parameter.1.parameter)
        }
        
        let emptyInput = SomeInput(parameters: inputParameters.reduce(into: [String: InputParameter](), { result, parameter in
            result[parameter.name] = parameter.value
        }))
        
        self.router.register({(clientInput: AnyPublisher<SomeInput, Never>, eventLoop: EventLoop, request: Vapor.Request) -> (
                    defaultInput: SomeInput,
                    output: AnyPublisher<Message<H.Response.Content>, Error>
                ) in
            var cancellables: Set<AnyCancellable> = []
            
            // We have to be able to handle both, incoming `clientInput` and
            // `observation`s coming from `ObservedObject`s. Thus we open a first
            //  gap in the publisher-chain where we can insert the `observation`s.
            let input = PassthroughSubject<Evaluation, Never>()
            
            // Here we just forward the `_input` into the `input`.
            clientInput.sink(receiveCompletion: { _ in
                input.send(completion: .finished)
            }, receiveValue: { value in
                input.send(.input(value))
            })
            .store(in: &cancellables)
            
            // This listener is notified each time an `ObservedObject` triggers this
            // instance of the endpoint. Each time we pipe the `observation` into
            // `input` along with its `promise` which must be succeeded further down
            // the line.
            let listener = DelegatingObservedListener<H>(eventLoop: eventLoop, callback: { observedObject, event in
                input.send(.observation(observedObject, event))
            })
            
            let context = endpoint.createConnectionContext(for: self)
            
            context.register(listener: listener)
            
            // We need a second gap in the publisher-chain here so we can map freely between
            // `value`s and `completion`s.
            let output: PassthroughSubject<Message<H.Response.Content>, Error> = PassthroughSubject()
            // Handle all incoming client-messages and observations one after another.
            // The `syncMap` automatically awaits the future, while `buffer` makes sure
            // messages are never dropped.
            input
                .buffer(size: Int.max, prefetch: .keepFull, whenFull: .dropNewest)
                .syncMap { evaluation -> EventLoopFuture<Apodini.Response<H.Response.Content>> in
                    switch evaluation {
                    case .input(let inputValue):
                        let request = WebSocketInput(inputValue, eventLoop: eventLoop, remoteAddress: request.remoteAddress)
                        return context.handle(request: request, eventLoop: eventLoop, final: false)
                    case let .observation(observedObject, event):
                        return context.handle(eventLoop: eventLoop, observedObject: observedObject, event: event)
                    }
                }
                .sink(
                    // The completion is also synchronized by `syncMap` it waits for any future
                    // to complete before forwarding it.
                    receiveCompletion: { completion in
                        let request = WebSocketInput(emptyInput, eventLoop: eventLoop, remoteAddress: request.remoteAddress)
                        Self.handleCompletion(completion: completion, context: context, request: request, output: output)
                        // We have to reference the cancellable here so it stays in memory and isn't cancled early.
                        cancellables.removeAll()
                    },
                    // The input was already handled and unwrapped by the `syncMap`. We just have to map the obtained
                    // `Response` to our `output` or handle the error returned from `handle`.
                    receiveValue: { result in
                        Self.handleValue(result: result, output: output)
                    }
                )
                .store(in: &cancellables)


            return (defaultInput: emptyInput, output: output.eraseToAnyPublisher())
        }, on: endpoint.absolutePath.build(with: WebSocketPathBuilder.self))
    }

    func retrieveParameter<Type>(
        _ parameter: EndpointParameter<Type>,
        for request: WebSocketInput
    ) throws -> Type?? where Type: Decodable, Type: Encodable {
        if let inputParameter = request.input.parameters[parameter.name] as? BasicInputParameter<Type> {
            return inputParameter.value
        } else {
            return nil
        }
    }

    func exportParameter<Type>(_ parameter: EndpointParameter<Type>) -> (String, WebSocketParameter) where Type: Decodable, Type: Encodable {
        (parameter.name, WebSocketParameter(BasicInputParameter<Type>()))
    }
    
    private static func handleCompletion<H: Handler>(
        completion: Subscribers.Completion<Never>,
        context: ConnectionContext<WebSocketInterfaceExporter, H>,
        request: WebSocketInput,
        output: PassthroughSubject<Message<H.Response.Content>, Error>
    ) {
        switch completion {
        case .finished:
            // We received the close-context message from the client. We evaluate the
            // `Handler` one more time before the connection is closed. We have to
            // manually await this future. We use an `emptyInput`, which is aggregated
            // to the latest input.
            context.handle(request: request, eventLoop: request.eventLoop, final: true).whenComplete { result in
                switch result {
                case .success(let response):
                    Self.handleCompletionResponse(response: response, output: output)
                case .failure(let error):
                    Self.handleError(error: error, output: output, close: true)
                }
            }
        }
    }
    
    private static func handleValue<C: Encodable>(
        result: Result<Apodini.Response<C>, Error>,
        output: PassthroughSubject<Message<C>, Error>
    ) {
        switch result {
        case .success(let response):
            Self.handleRegularResponse(response: response, output: output)
        case .failure(let error):
            Self.handleError(error: error, output: output)
        }
    }
    
    private static func handleCompletionResponse<C: Encodable>(
        response: Apodini.Response<C>,
        output: PassthroughSubject<Message<C>, Error>
    ) {
        if let content = response.content {
            output.send(.message(content))
        }
        output.send(completion: .finished)
    }
    
    private static func handleRegularResponse<C: Encodable>(
        response: Apodini.Response<C>,
        output: PassthroughSubject<Message<C>, Error>
    ) {
        if let content = response.content {
            output.send(.message(content))
        }
        if response.connectionEffect == .close {
            output.send(completion: .finished)
        }
    }
    
    private static func handleError<C: Encodable>(
        error: Error,
        output: PassthroughSubject<Message<C>, Error>,
        close: Bool = false
    ) {
        let error = error.apodiniError
        switch error.option(for: .webSocketConnectionConsequence) {
        case .none:
            output.send(.error(error.wsError))
            if close {
                output.send(completion: .finished)
            }
        case .closeContext:
            output.send(.error(error.wsError))
            output.send(completion: .finished)
        case .closeChannel:
            output.send(completion: .failure(error.wsError))
        }
    }
}


// MARK: Handling of ObservedObject

private struct DelegatingObservedListener<H: Handler>: ObservedListener {
    func onObservedDidChange(_ observedObject: AnyObservedObject, _ event: TriggerEvent) {
        callback(observedObject, event)
    }
    
    init(eventLoop: EventLoop, callback: @escaping (AnyObservedObject, TriggerEvent) -> Void) {
        self.eventLoop = eventLoop
        self.callback = callback
    }
    
    var eventLoop: EventLoop
    
    var callback: (AnyObservedObject, TriggerEvent) -> Void
}

private enum Evaluation {
    case input(SomeInput)
    case observation(AnyObservedObject, TriggerEvent)
}

// MARK: Input Definition

/// A struct that wrapps the `WebSocketInterfaceExporter`'s internal representation of
/// an `@Parameter`.
public struct WebSocketParameter {
    internal var parameter: InputParameter
    
    internal init(_ parameter: InputParameter) {
        self.parameter = parameter
    }
}

/// A struct that wrapps the `WebSocketInterfaceExporter`'s internal representation of
/// the complete input of an endpoint.
public struct WebSocketInput: ExporterRequestWithEventLoop {
    internal var input: SomeInput
    public let eventLoop: EventLoop
    public let remoteAddress: SocketAddress?
    
    internal init(_ input: SomeInput, eventLoop: EventLoop, remoteAddress: SocketAddress? = nil) {
        self.input = input
        self.eventLoop = eventLoop
        self.remoteAddress = remoteAddress
    }
}


// MARK: Input Accumulation

extension WebSocketInput: Apodini.Reducible {
    public func reduce(to new: WebSocketInput) -> WebSocketInput {
        var newParameters: [String: InputParameter] = [:]
        for (name, value) in new.input.parameters {
            if let reducible = self.input.parameters[name] as? ReducibleParameter {
                newParameters[name] = reducible.reduce(to: value)
            } else {
                newParameters[name] = value
            }
        }
        return WebSocketInput(SomeInput(parameters: newParameters), eventLoop: new.eventLoop, remoteAddress: new.remoteAddress)
    }
}

private protocol ReducibleParameter {
    func reduce(to new: InputParameter) -> InputParameter
}

extension BasicInputParameter: ReducibleParameter {
    func reduce(to new: InputParameter) -> InputParameter {
        if let newParameter = new as? Self {
            switch newParameter.value {
            case .some:
                return new
            case .none:
                return self
            }
        } else {
            return new
        }
    }
}

// MARK: WSError Conformance

private extension ApodiniError {
    var wsError: WSError {
        switch self.option(for: .webSocketConnectionConsequence) {
        case .closeContext:
            return FatalWSError(reason: self.webSocketMessage, code: self.option(for: .webSocketErrorCode))
        default:
            return ModerateWSError(reason: self.webSocketMessage)
        }
    }
}

private struct ModerateWSError: WSError {
    var reason: String
}

private struct FatalWSError: WSClosingError {
    var reason: String
    var code: WebSocketErrorCode
}



#if DEBUG
extension ApodiniError {
    var webSocketMessage: String {
        return self.message(with: messagePrefix(for: self))
    }
}

private func messagePrefix(for error: ApodiniError) -> String? {
    switch error.option(for: .errorType) {
    case .badInput:
        return "You messed up"
    case .notFound:
        return "Wow...such empty"
    case .unauthenticated:
        return "Who even are you"
    case .forbidden:
        return "You shall not pass!"
    case .serverError:
        return "I messed up"
    case .notAvailable:
        return "Not now...I'm busy"
    case .other:
        return "Something's wrong, I can feel it"
    }
}
#else
extension ApodiniError {
    var webSocketMessage: String {
        self.standardMessage
    }
}
#endif

