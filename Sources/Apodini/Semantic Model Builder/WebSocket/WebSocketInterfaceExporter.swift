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

extension AnyInput: ExporterRequest { }


class WebSocketInterfaceExporter: InterfaceExporter {
    private let app: Application
    
    private let router: WebSocketInfrastructure.Router
    
    required init(_ app: Application) {
        self.app = app
        self.router = VaporWSRouter(app)
    }
    
    func export<C: Component>(_ endpoint: Endpoint<C>) {
        let defaultInput = AnyInput()

        self.router.register({ (input: AnyPublisher<AnyInput, Never>, eventLoop: EventLoop, database: Database?) -> (defaultInput: AnyInput, output: AnyPublisher<Message<AnyEncodable>, Error>) in
            let defaultInput = defaultInput
            
            let requestHandler = endpoint.createRequestHandler(for: self)

            let output: PassthroughSubject<Message<AnyEncodable>, Error> = PassthroughSubject()
            var inputCancellable: AnyCancellable? = nil
            // TODO: synchronize
            inputCancellable = input.sink(receiveCompletion: { completion in
                inputCancellable?.cancel()

                // TODO: implement
                output.send(completion: .finished)
            }, receiveValue: { inputValue in
                requestHandler.handleRequest(request: inputValue, eventLoop: eventLoop, database: database).whenComplete { result in
                    switch result {
                    case .success(let response):
                        output.send(.send(AnyEncodable(value: response)))
                    case .failure(let error):
                        output.send(.error(error))
                    }
                }
            })


            return (defaultInput: defaultInput, output: output.eraseToAnyPublisher())
        }, on: WebSocketPathBuilder(endpoint.absolutePath).pathIdentifier)
    }
    
    func retrieveParameter<Type>(_ parameter: EndpointParameter<Type>, for request: AnyInput) throws -> Any?? where Type : Decodable, Type : Encodable {
        if let value = request.parameters[parameter.name] {
            return .some(value)
        }
        return nil
    }
}

// MARK: Input Helpers
fileprivate extension SomeInput {
    class WebSocketInputExtractor: EndpointParameterVisitor {
        func visit<Element>(parameter: EndpointParameter<Element>) -> InputParameter where Element : Decodable, Element : Encodable {
            parameter.input()
        }
    }
    
    
    init<C: Component>(from endpoint: Endpoint<C>, with parameterNames: [UUID: String]) {
        let extractor = WebSocketInputExtractor()
        self.init(parameters: endpoint.parameters.reduce(into: [String: InputParameter](), { (result, endpointParameter) in
            if let name = parameterNames[endpointParameter.id] {
                result[name] = endpointParameter.accept(extractor)
            }
        }))
    }
}

fileprivate extension EndpointParameter {
    func input() -> InputParameter {
        let m: WebSocketInfrastructure.Mutability = self.options.option(for: .mutability) == .constant ? .constant : .variable

//        switch self.necessity {
//        case .optional:
//
//        case .required:
//
//        }
        
//        if Element.self is ExpressibleByNilLiteral.Type || self.defaultValue != nil {
//            return WebSocketInfrastructure.Parameter<Element>(mutability: m, necessity: .optional)
//        } else  {
//            return WebSocketInfrastructure.Parameter<Element>(mutability: m, necessity: .required)
//        }
        
        return WebSocketInfrastructure.Parameter<Type>(mutability: m, necessity: .optional)
    }
}
