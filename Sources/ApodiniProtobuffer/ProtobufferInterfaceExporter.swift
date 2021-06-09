//
//  Created by Nityananda on 03.12.20.
//

import Apodini
import ApodiniVaporSupport
import ApodiniGRPC
import ApodiniTypeReflection
import ApodiniUtils
@_implementationOnly import class Vapor.Application

public final class ProtobufferInterfaceExporter: GRPCDependentStaticConfiguration {
    var configuration: ProtobufferExporterConfiguration
    
    public init() {
        self.configuration = ProtobufferExporterConfiguration()
    }
    
    public func configure(_ app: Apodini.Application, parentConfiguration: GRPCExporterConfiguration) {
        /// Set configartion of parent
        self.configuration.parentConfiguration = parentConfiguration
        
        /// Instanciate exporter
        let protobufferExporter = _ProtobufferInterfaceExporter(app, self.configuration)
        
        /// Insert exporter into `SemanticModelBuilder`
        let builder = app.exporters.semanticModelBuilderBuilder
        app.exporters.semanticModelBuilderBuilder = { model in
            builder(model).with(exporter: protobufferExporter)
        }
    }
}

// swiftlint:disable type_name
final class _ProtobufferInterfaceExporter: StaticInterfaceExporter {
    // MARK: Nested Types
    struct Error: Swift.Error, CustomDebugStringConvertible {
        let message: String
    
        var debugDescription: String {
            "ProtobufferInterfaceExporterError: \(message)"
        }
    }
    
    // MARK: Properties
    private let app: Apodini.Application
    private let builder: Builder
    private let exporterConfiguration: ProtobufferExporterConfiguration
    
    private var messages: Set<ProtobufferMessage> = .init()
    private var services: Set<ProtobufferService> = .init()
    
    // MARK: Initialization
    init(_ app: Apodini.Application,
         _ exporterConfiguration: ProtobufferExporterConfiguration = ProtobufferExporterConfiguration()) {
        self.app = app
        self.exporterConfiguration = exporterConfiguration
        self.builder = Builder(configuration: self.exporterConfiguration.parentConfiguration)
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
    
    struct Builder {
        let parentConfiguration: GRPCExporterConfiguration
        
        init(configuration: GRPCExporterConfiguration) {
            guard let castedConfiguration = dynamicCast(configuration, to: GRPCExporterConfiguration.self) else {
                fatalError("Wrong configuration type passed to exporter!")
            }
            
            self.parentConfiguration = castedConfiguration
        }
        
        func buildMessage(_ type: Any.Type) throws -> Node<ProtobufferMessage> {
            try buildCompositeMessage(type) ?? buildScalarMessage(type)
        }
        
        func buildCompositeMessage(_ type: Any.Type) throws -> Tree<ProtobufferMessage> {
            try ReflectionInfo.node(type)
                .edited(handleOptional)?
                .edited(handleArray)?
                .edited(handlePrimitiveType)?
                .edited(handleUUID)?
                .map(ProtobufferMessage.Property.init)
                .map {
                    $0.map(handleUUIDProperty)
                }
                .map {
                    $0.map(handleVariableWidthInteger)
                }
                .contextMap(ProtobufferMessage.init)
                .compactMap { $0 }?
                .filter(!\.isPrimitive)
        }
        
        func buildScalarMessage(_ type: Any.Type) -> Node<ProtobufferMessage> {
            let typeName = String(describing: type)
            
            return Node(
                value: ProtobufferMessage(
                    name: "\(typeName)Message",
                    properties: [
                        handleVariableWidthInteger(
                            .init(
                                fieldRule: .required,
                                name: "value",
                                typeName: typeName.lowercased(),
                                uniqueNumber: 1
                            )
                        )
                    ]
                ),
                children: []
            )
        }
    }
}

private extension _ProtobufferInterfaceExporter {
    func exportThrows<H: Handler>(_ endpoint: Endpoint<H>) throws {
        // Output
        let outputNode = try builder.buildMessage(endpoint[ResponseType.self].type)
        messages.formUnion(outputNode.collectValues())
        
        // Input
        let parameterNodes = try endpoint.parameters.map { parameter in
            try builder.buildMessage(parameter.propertyType)
        }
        for parameterNode in parameterNodes where !parameterNode.value.isPrimitive {
            messages.formUnion(parameterNode.collectValues())
        }
        
        let source = zip(endpoint.parameters, parameterNodes).enumerated()
        let handlerProperties = source
            .map { item -> ProtobufferMessage.Property in
                let (index, (parameter, node)) = item
                
                let fieldRule: ProtobufferMessage.Property.FieldRule
                fieldRule = parameter.nilIsValidValue ? .optional : .required
                let name = parameter.name
                let typeName = node.value.isPrimitive
                    ? Array(node.value.properties)[0].typeName
                    : node.value.name
                
                let fieldTag = parameter.option(for: .gRPC)?.fieldNumber
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
            methods: [
                .init(
                    name: gRPCMethodName(from: endpoint),
                    input: handlerMessage,
                    ouput: outputNode.value
                )
            ]
        )
        services.insert(service)
    }
}

// MARK: - _ProtobufferInterfaceExporter.Builder Implementation

private extension _ProtobufferInterfaceExporter.Builder {
    func handleUUIDProperty(
        _ property: ProtobufferMessage.Property
    ) -> ProtobufferMessage.Property {
        guard property.typeName == "UUIDMessage" else {
            return property
        }
        
        return .init(
            fieldRule: property.fieldRule,
            name: property.name,
            typeName: "string",
            uniqueNumber: property.uniqueNumber
        )
    }
    
    func handleVariableWidthInteger(
        _ property: ProtobufferMessage.Property
    ) -> ProtobufferMessage.Property {
        guard ["int", "uint"].contains(property.typeName) else {
            return property
        }
        
        let suffix = String(self.parentConfiguration.integerWidth.rawValue)
        let typeName = property.typeName + suffix
        
        return .init(
            fieldRule: property.fieldRule,
            name: property.name,
            typeName: typeName,
            uniqueNumber: property.uniqueNumber
        )
    }
}

private extension ProtobufferMessage {
    /// .
    ///
    /// The implementation is less than ideal,
    /// but it is sufficient for now.
    var isPrimitive: Bool {
        // TypeInfo.compatibleName is leaking...
        guard name.hasSuffix("Message") else {
            return true
        }
        
        // Builder.buildScalarMessage is leaking...
        guard properties.count == 1 else {
            return false
        }
        
        let typeName = Array(properties)[0].typeName
        return typeName + "message" == name.lowercased()
    }
}

// MARK: - _ProtobufferInterfaceExporter: CustomStringConvertible

extension _ProtobufferInterfaceExporter: CustomStringConvertible {
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
