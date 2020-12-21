//
//  WebSocketInterfaceExporter.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor
import Fluent
@_implementationOnly import WebSocketInfrastructure
import OpenCombine
@_implementationOnly import Runtime


private struct WebSocketRequest: Request {
    var eventLoop: EventLoop
    var database: Fluent.Database?
    
    var parameterNames: [UUID: String]
    
    var input: AnyInput
    
    func parameter<T: Codable>(for parameter: UUID) throws -> T? {
        if let name = parameterNames[parameter] {
            if let inputParameter = input.parameters[name] {
                if let parameter = inputParameter as? WebSocketInfrastructure.Parameter<T> {
                    return parameter.value
                }
            }
        }
        return nil
    }
    
    var description: String {
        if let database = self.database {
            return "WebSocketRequest(input: \(input), eventLoop: \(eventLoop), database: \(database))"
        } else {
            return "WebSocketRequest(input: \(input), eventLoop: \(eventLoop))"
        }
    }
}


class WebSocketInterfaceExporter: InterfaceExporter {
    private let app: Application
    
    private let router: WebSocketInfrastructure.Router
    
    required init(_ app: Application) {
        self.app = app
        self.router = VaporWSRouter(app)
    }
    
    func export(_ endpoint: Endpoint) {
        let parameterNames: [UUID: String] = endpoint.parameters.reduce(into: [UUID: String](), { (result, endpointParameter) in
            result[endpointParameter.id] = endpointParameter.name ?? endpointParameter.label.trimmingCharacters(in: ["_"])
        })
        
        let defaultInput = AnyInput(from: endpoint, with: parameterNames)

        self.router.register({ (input: AnyPublisher<AnyInput, Never>, eventLoop: EventLoop, database: Database) -> (defaultInput: AnyInput, output: AnyPublisher<Message<AnyEncodable>, Error>) in
            let defaultInput = defaultInput
            
            let output: PassthroughSubject<Message<AnyEncodable>, Error> = PassthroughSubject()
            var inputCancellable: AnyCancellable? = nil
            // TODO: synchronize
            inputCancellable = input.sink(receiveCompletion: { completion in
                inputCancellable?.cancel()
                
                // TODO: implement
                output.send(completion: .finished)
            }, receiveValue: { inputValue in
                let request = WebSocketRequest(eventLoop: eventLoop, database: database, parameterNames: parameterNames, input: inputValue)
                
                endpoint.requestHandler(request).whenComplete { result in
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
}

// MARK: Input Helpers
fileprivate extension AnyInput {
    init(from endpoint: Endpoint, with parameterNames: [UUID: String]) {
        self.init(parameters: endpoint.parameters.reduce(into: [String: InputParameter](), { (result, endpointParameter) in
            if let name = parameterNames[endpointParameter.id] {
                result[name] = endpointParameter.input()
            }
        }))
    }
}

fileprivate extension EndpointParameter {
    class WebSocketInputBuilder: RequestInjectableVisitor {
        var inputParameter: InputParameter?
        
        func visit<Element>(_ parameter: Parameter<Element>) {
            self.inputParameter = parameter.input()
        }
        
        func build() -> InputParameter {
            guard let parameter = self.inputParameter else {
                preconditionFailure("WebSocketInputBuilder could not generate InputParameter")
            }
            return parameter
        }
    }

    func input() -> InputParameter {
        let inputBuilder = WebSocketInputBuilder()
        
        self.requestInjectable.accept(inputBuilder)
        
        return inputBuilder.build()
    }
}

extension Parameter {
    fileprivate func input() -> InputParameter {
        let m: WebSocketInfrastructure.Mutability = self.option(for: .mutability) == .constant ? .constant : .variable

        if Element.self is ExpressibleByNilLiteral.Type || self.defaultValue != nil {
            return WebSocketInfrastructure.Parameter<Element>(mutability: m, necessity: .optional)
        } else  {
            return WebSocketInfrastructure.Parameter<Element>(mutability: m, necessity: .required)
        }
    }
}
