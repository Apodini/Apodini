//
//  Created by Nityananda on 03.12.20.
//

@_implementationOnly import class Vapor.Application

class ProtobufferInterfaceExporter: StaticInterfaceExporter {
    // MARK: Nested Types
    struct Error: Swift.Error {
        let message: String
    }

    internal enum Builder {}
    
    // MARK: Properties
    private let app: Application
    
    private var messages: Set<ProtobufferMessage> = .init()
    private var services: Set<ProtobufferService> = .init()
    
    // MARK: Initialization
    required init(_ app: Application) {
        self.app = app
    }
    
    // MARK: Methods
    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        do {
            try exportThrows(endpoint)
        } catch {
            app.logger.error("\(error)")
        }
    }
    
    func finishedExporting(_ webService: WebServiceModel) {
        let description = self.description
        
        app.vapor.app.get("apodini", "proto") { _ in
            description
        }
    }
}

private extension ProtobufferInterfaceExporter {
    func exportThrows<H: Handler>(_ endpoint: Endpoint<H>) throws {
        // Output
        let outputNode = try Builder.buildMessage(endpoint.responseType)
        messages.formUnion(outputNode.collectValues())
        
        // Input
        let parameterNodes = try endpoint.parameters.map { parameter in
            try Builder.buildMessage(parameter.propertyType)
        }
        for parameterNode in parameterNodes {
            messages.formUnion(parameterNode.collectValues())
        }
        
        let source = zip(endpoint.parameters, parameterNodes).enumerated()
        let handlerProperties = source
            .map { item -> ProtobufferMessage.Property in
                let (index, (parameter, node)) = item
                
                let fieldRule: ProtobufferMessage.Property.FieldRule
                fieldRule = parameter.nilIsValidValue ? .optional : .required
                let name = parameter.name
                let typeName = node.value.name
                
                let fieldTag = parameter.options.option(for: .gRPC)?.fieldNumber
                let uniqueNumber = fieldTag ?? (index + 1)
                
                return ProtobufferMessage.Property(
                    fieldRule: fieldRule,
                    name: name,
                    typeName: typeName,
                    uniqueNumber: uniqueNumber
                )
            }
        
        // Handler
        let handlerMessage = ProtobufferMessage(
            name: "\(H.self)Message",
            properties: Set(handlerProperties)
        )
        messages.insert(handlerMessage)
        
        // Service
        let service = ProtobufferService(
            name: gRPCServiceName(from: endpoint),
            methods: [.init(
                name: gRPCMethodName(from: endpoint),
                input: handlerMessage,
                ouput: outputNode.value
            )]
        )
        services.insert(service)
    }
}

// MARK: - ProtobufferInterfaceExporter.Builder Implementation

extension ProtobufferInterfaceExporter.Builder {
    static func buildMessage(_ type: Any.Type) throws -> Node<ProtobufferMessage> {
        let node = try EnrichedInfo.node(type)
            .edited(handleOptional)?
            .edited(handleArray)?
            .edited(handlePrimitiveType)?
            .map(ProtobufferMessage.Property.init)
            .contextMap(ProtobufferMessage.init)
            .compactMap { $0 }?
            .filter(isNotPrimitive)
        
        return node ?? Self.buildScalarMessage(type)
    }
    
    static func buildScalarMessage(_ type: Any.Type) -> Node<ProtobufferMessage> {
        Node(
            value: ProtobufferMessage(
                name: "\(type)Message",
                properties: [
                    .init(
                        fieldRule: .required,
                        name: "value",
                        typeName: "\(type)".lowercased(),
                        uniqueNumber: 1
                    )
                ]
            ),
            children: []
        )
    }
}

private func isNotPrimitive(_ message: ProtobufferMessage) -> Bool {
    message.name.hasSuffix("Message")
}

// MARK: - ProtobufferInterfaceExporter: CustomStringConvertible

extension ProtobufferInterfaceExporter: CustomStringConvertible {
    public var description: String {
        let protoFile = [
            #"syntax = "proto3";"#,
            services.description,
            messages.description
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")
        
        return protoFile
    }
}

extension Set where Element == ProtobufferService {
    var description: String {
        sorted(by: \.name)
            .map(\.description)
            .joined(separator: "\n\n")
    }
}

extension Set where Element == ProtobufferMessage {
    var description: String {
        sorted(by: \.name)
            .map(\.description)
            .joined(separator: "\n\n")
    }
}
