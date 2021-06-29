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
final class WebSocketInterfaceExporter: LegacyInterfaceExporter {
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
        
        let decodingStrategy = InterfaceExporterLegacyStrategy(self).applied(to: endpoint)
        
        let defaultValueStore = endpoint[DefaultValueStore.self]
        
        self.router.register({(clientInput: AnyPublisher<SomeInput, Never>, eventLoop: EventLoop, request: Vapor.Request) -> (
                    defaultInput: SomeInput,
                    output: AnyPublisher<Message<H.Response.Content>, Error>
                ) in
            
            // We need a new `Delegate` for each connection
            var delegate = Delegate(endpoint.handler, .required)
            
            var cancellables: Set<AnyCancellable> = []
            
            // We need a gap in the publisher-chain here so we can map freely between
            // `value`s and `completion`s.
            let output: PassthroughSubject<Message<H.Response.Content>, Error> = PassthroughSubject()
            
            clientInput
            .buffer(size: Int.max, prefetch: .keepFull, whenFull: .dropNewest)
            .reduce()
            .map { (someInput: SomeInput) -> (DefaultRequestBasis, SomeInput) in
                (DefaultRequestBasis(base: someInput, remoteAddress: request.remoteAddress, information: request.information), someInput)
            }
            .decode(using: decodingStrategy, with: eventLoop)
            .insertDefaults(with: defaultValueStore)
            .validateParameterMutability()
            .cache()
            .subscribe(to: &delegate)
            .evaluate(on: &delegate)
            .cancel(if: { result in
                switch result {
                case let .success(response):
                    if response.connectionEffect == .close {
                        return true
                    } else {
                        return false
                    }
                case let .failure(error):
                    switch error.apodiniError.option(for: .webSocketConnectionConsequence) {
                    case .closeChannel, .closeContext:
                        return true
                    case .none:
                        return false
                    }
                }
            })
            .sink(
                receiveCompletion: { _ in // is always .finished
                    // We have to reference the cancellable here so it stays in memory and isn't cancled early.
                    cancellables.removeAll()
                    output.send(completion: .finished)
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
        for request: SomeInput
    ) throws -> Type?? where Type: Decodable, Type: Encodable {
        if let inputParameter = request.parameters[parameter.name] as? BasicInputParameter<Type> {
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
        handler: inout Delegate<H>,
        request: Apodini.Request,
        output: PassthroughSubject<Message<H.Response.Content>, Error>
    ) {
        switch completion {
        case .finished:
            // We received the close-context message from the client. We evaluate the
            // `Handler` one more time before the connection is closed. We have to
            // manually await this future. We use an `emptyInput`, which is aggregated
            // to the latest input.
            request.evaluate(on: &handler, .end).whenComplete { (result: Result<Apodini.Response<H.Response.Content>, Error>) in
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


// MARK: Input Definition

/// A struct that wrapps the `WebSocketInterfaceExporter`'s internal representation of
/// an `@Parameter`.
public struct WebSocketParameter {
    internal var parameter: InputParameter
    
    internal init(_ parameter: InputParameter) {
        self.parameter = parameter
    }
}


// MARK: Input Accumulation

extension SomeInput: Reducible {
    func reduce(with new: SomeInput) -> SomeInput {
        var newParameters: [String: InputParameter] = [:]
        for (name, value) in new.parameters {
            if let reducible = self.parameters[name] as? ReducibleParameter {
                newParameters[name] = reducible.reduce(to: value)
            } else {
                newParameters[name] = value
            }
        }
        return SomeInput(parameters: newParameters)
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

