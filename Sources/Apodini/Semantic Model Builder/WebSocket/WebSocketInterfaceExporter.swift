//
//  WebSocketInterfaceExporter.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

@_implementationOnly import Vapor
@_implementationOnly import Fluent
@_implementationOnly import WebSocketInfrastructure
import OpenCombine
@_implementationOnly import Runtime

extension SomeInput: ExporterRequest, Reducible {
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


class WebSocketInterfaceExporter: InterfaceExporter {
    typealias ExporterRequest = SomeInput
    
    typealias EndpointExportOuput = Void
    
    typealias ParameterExportOuput = InputParameter
    
    
    private let app: Application
    
    private let router: WebSocketInfrastructure.Router
    
    required init(_ app: Application) {
        self.app = app
        self.router = VaporWSRouter(app)
    }
    
    func export<C: Component>(_ endpoint: Endpoint<C>) {
        let inputParameters: [(String, InputParameter)] = endpoint.exportParameters(on: self)
        
        let emptyInput = SomeInput(parameters: inputParameters.reduce(into: [String: InputParameter](), { result, parameter in
            result[parameter.0] = parameter.1
        }))
        
        self.router.register({(input: AnyPublisher<SomeInput, Never>, eventLoop: EventLoop, _: Database?) -> (
                    defaultInput: SomeInput,
                    output: AnyPublisher<Message<AnyEncodable>, Error>
                ) in
            var context = endpoint.createConnectionContext(for: self)

            let output: PassthroughSubject<Message<AnyEncodable>, Error> = PassthroughSubject()
            var inputCancellable: AnyCancellable?
            #warning("""
                The current sink-based implementation does not synchronize requests where 'handle' returns an 'EventLoopFuture'.
                This can lead to undefined behavior on parallel requests.
            """)
            inputCancellable = input.sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    Self.handleInputCompletion(with: emptyInput, using: &context, on: eventLoop, output: output)
                }
                
                inputCancellable?.cancel()
            }, receiveValue: { inputValue in
                Self.handleRegularInput(with: inputValue, using: &context, on: eventLoop, output: output)
            })


            return (defaultInput: emptyInput, output: output.eraseToAnyPublisher())
        }, on: WebSocketPathBuilder(endpoint.absolutePath).pathIdentifier)
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
    
    private static func handleInputCompletion(
        with emptyInput: SomeInput,
        using context: inout AnyConnectionContext<WebSocketInterfaceExporter>,
        on eventLoop: EventLoop,
        output: PassthroughSubject<Message<AnyEncodable>, Error>) {
        context.handle(request: emptyInput, eventLoop: eventLoop, final: true).whenComplete { result in
            switch result {
            case .success(.nothing):
                output.send(completion: .finished)
            case .success(.send(let message)):
                output.send(.message(message))
                output.send(completion: .finished)
            case .success(.final(let message)):
                output.send(.message(message))
                output.send(completion: .finished)
            case .success(.end):
                output.send(completion: .finished)
            case .failure(let error):
                output.send(completion: .failure(error))
            }
        }
    }
    
    private static func handleRegularInput(
        with latestInput: SomeInput,
        using context: inout AnyConnectionContext<WebSocketInterfaceExporter>,
        on eventLoop: EventLoop,
        output: PassthroughSubject<Message<AnyEncodable>, Error>) {
        context.handle(request: latestInput, eventLoop: eventLoop, final: false).whenComplete { result in
            switch result {
            case .success(.nothing):
                break
            case .success(.send(let message)):
                output.send(.message(message))
            case .success(.final(let message)):
                output.send(.message(message))
                output.send(completion: .finished)
            case .success(.end):
                output.send(completion: .finished)
            case .failure(let error):
                output.send(.error(error))
            }
        }
    }
}
