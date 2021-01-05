//
//  WebSocketInterfaceExporter.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

@_implementationOnly import Vapor
@_implementationOnly import Fluent
@_implementationOnly import WebSocketInfrastructure
@_implementationOnly import OpenCombine
@_implementationOnly import Runtime

extension SomeInput: ExporterRequest { }


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
        
        let defaultInput = SomeInput(parameters: inputParameters.reduce(into: [String: InputParameter](), { result, parameter in
            result[parameter.0] = parameter.1
        }))

        self.router.register({(input: AnyPublisher<SomeInput, Never>, eventLoop: EventLoop, _: Database?) -> (
                    defaultInput: SomeInput,
                    output: AnyPublisher<Message<AnyEncodable>, Error>
                ) in
            let defaultInput = defaultInput
            
            var context = endpoint.createConnectionContext(for: self)

            let output: PassthroughSubject<Message<AnyEncodable>, Error> = PassthroughSubject()
            var inputCancellable: AnyCancellable?
            #warning("""
                The current sink-based implementation does not synchronize requests where 'handle' returns an 'EventLoopFuture'.
                This can lead to undefined behavior on parallel requests.
            """)
            inputCancellable = input.sink(receiveCompletion: { completion in
                inputCancellable?.cancel()

                #warning("The WebSocketExporter does not handle 'Action' yet. Using anything but '.send' or '.final' results in a server-crash.")
                output.send(completion: .finished)
            }, receiveValue: { inputValue in
                context.handle(request: inputValue, eventLoop: eventLoop).whenComplete { result in
                    switch result {
                    case .success(let response):
                        #warning(
                            """
                            The WebSocketExporter does not handle 'Action' yet.
                            Using anything but '.send' or '.final' results in a server-crash.
                            """
                        )
                        // As stated in the warning above the WebSocketExporter crashes on `.end` and `.nothing`
                        // swiftlint:disable:next force_unwrapping
                        output.send(.message(response.element!))
                    case .failure(let error):
                        output.send(.error(error))
                    }
                }
            })


            return (defaultInput: defaultInput, output: output.eraseToAnyPublisher())
        }, on: WebSocketPathBuilder(endpoint.absolutePath).pathIdentifier)
    }
    
    func retrieveParameter<Type>(
        _ parameter: EndpointParameter<Type>,
        for request: SomeInput
    ) throws -> Type?? where Type: Decodable, Type: Encodable {
        if let inputParameter = request.parameters[parameter.name] as? WebSocketInfrastructure.NullableOptionalVariableParameter<Type> {
            return inputParameter.value
        } else {
            return nil
        }
    }
    
    func exportParameter<Type>(_ parameter: EndpointParameter<Type>) -> (String, InputParameter) where Type: Decodable, Type: Encodable {
        (parameter.name, WebSocketInfrastructure.NullableOptionalVariableParameter<Type>())
    }
}
