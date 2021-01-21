//
//  WebSocketInterfaceExporter.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Fluent
@_implementationOnly import WebSocketInfrastructure
@_implementationOnly import OpenCombine
@_implementationOnly import Runtime
import NIOWebSocket

// MARK: Exporter

class WebSocketInterfaceExporter: StandardErrorCompliantExporter {
    private let app: Application
    
    private let router: WebSocketInfrastructure.Router
    
    required init(_ app: Application) {
        self.app = app
        self.router = VaporWSRouter(app.vapor.app)
    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        let inputParameters: [(name: String, value: InputParameter)] = endpoint.exportParameters(on: self)
        
        let emptyInput = SomeInput(parameters: inputParameters.reduce(into: [String: InputParameter](), { result, parameter in
            result[parameter.name] = parameter.value
        }))
        
        self.router.register({(input: AnyPublisher<SomeInput, Never>, eventLoop: EventLoop, _: Database?) -> (
                    defaultInput: SomeInput,
                    output: AnyPublisher<Message<AnyEncodable>, Error>
                ) in
            var context = endpoint.createConnectionContext(for: self)
            
            let output: PassthroughSubject<Message<AnyEncodable>, Error> = PassthroughSubject()
            
            var cancellables: Set<AnyCancellable> = []
            input.mapError { _ -> Error in }
            // Handle all incoming client-messages one after another. The `syncMap` automatically
            // awaits the future and unwrapps it.
            .syncMap { inputValue -> EventLoopFuture<Response<AnyEncodable>> in
                context.handle(request: inputValue, eventLoop: eventLoop, final: false)
            }
            .sink(
                // The completion is also synchronized by `syncMap` it waits for any future
                // to complete before forwarding it.
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        // We received the close-context message from the client. We evaluate the
                        // `Handler` one more time before the connection is closed. We have to
                        // manually await this future. We use an `emptyInput`, which is aggregated
                        // to the latest input.
                        context.handle(request: emptyInput, eventLoop: eventLoop, final: true).whenComplete { result in
                            switch result {
                            case .success(let action):
                                Self.handleInputCompletion(result: action, output: output)
                            case .failure(let error):
                                Self.handleError(error: error, output: output, close: true)
                            }
                        }
                    case .failure(let error):
                        Self.handleError(error: error, output: output)
                    }
                    // We have to reference the cancellable here so it stays in memory and isn't cancled early.
                    cancellables.removeAll()
                },
                // The input was already handled and unwrapped by the `syncMap`. We just have to map the obtained
                // `Action` to our `output`.
                receiveValue: { inputValue in
                    Self.handleRegularInput(result: inputValue, output: output)
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
        if let inputParameter = request.parameters[parameter.name] as? WebSocketInfrastructure.BasicInputParameter<Type> {
            return inputParameter.value
        } else {
            return nil
        }
    }
    
    func exportParameter<Type>(_ parameter: EndpointParameter<Type>) -> (String, InputParameter) where Type: Decodable, Type: Encodable {
        (parameter.name, WebSocketInfrastructure.BasicInputParameter<Type>())
    }
    
    static func messagePrefix(for error: StandardErrorContext) -> String {
        #if DEBUG
        return Self.debugModeMessagePrefix(for: error)
        #else
        return Self.productionModeMessagePrefix(for: error)
        #endif
    }
    
    private static func debugModeMessagePrefix(for error: StandardErrorContext) -> String {
        switch error.option(for: .wsErrorType) {
        case .badInput:
            return "You fucked up"
        case .notFound:
            return "Wow...such empty"
        case .unauthenticated:
            return "Who even are you"
        case .forbidden:
            return "You shall not pass!"
        case .serverError:
            return "I fucked up"
        case .notAvailable:
            return "Not now...I'm busy"
        case .other:
            return "Something's wrong, I can feel it"
        }
    }
    
    private static func productionModeMessagePrefix(for error: StandardErrorContext) -> String {
        switch error.option(for: .wsErrorType) {
        case .badInput:
            return "Bad Input"
        case .notFound:
            return "Resource Not Found"
        case .unauthenticated:
            return "Unauthenticated"
        case .forbidden:
            return "Forbidden"
        case .serverError:
            return "Unexpected Server Error"
        case .notAvailable:
            return "Resource Not Available"
        case .other:
            return "Error"
        }
    }
    
    private static func handleInputCompletion(
        result: Response<AnyEncodable>,
        output: PassthroughSubject<Message<AnyEncodable>, Error>) {
        switch result {
        case .nothing:
            output.send(completion: .finished)
        case .send(let message):
            output.send(.message(message))
            output.send(completion: .finished)
        case .final(let message):
            output.send(.message(message))
            output.send(completion: .finished)
        case .end:
            output.send(completion: .finished)
        }
    }
    
    private static func handleRegularInput(
        result: Response<AnyEncodable>,
        output: PassthroughSubject<Message<AnyEncodable>, Error>) {
        switch result {
        case .nothing:
            break
        case .send(let message):
            output.send(.message(message))
        case .final(let message):
            output.send(.message(message))
            output.send(completion: .finished)
        case .end:
            output.send(completion: .finished)
        }
    }
    
    private static func handleError(
        error: Error,
        output: PassthroughSubject<Message<AnyEncodable>, Error>,
        close: Bool = false) {
        let error = error.apodiniError
        switch error.option(for: .wsConnectionConsequence) {
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

// MARK: Input Accumulation

extension SomeInput: ExporterRequest {
    func reduce(to new: SomeInput) -> SomeInput {
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

private extension StandardError {
    var wsError: WSError {
        switch self.option(for: .wsConnectionConsequence) {
        case .closeContext:
            return FatalWSError(reason: self.message(for: WebSocketInterfaceExporter.self), code: self.option(for: .webSocketErrorCode))
        default:
            return ModerateWSError(reason: self.message(for: WebSocketInterfaceExporter.self))
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
