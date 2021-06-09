//
//  GRPCInterfaceExporter.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Foundation
import NIO
import Apodini
@_implementationOnly import NIOHPACK
@_implementationOnly import ProtobufferCoding

/// Public Apodini Interface Exporter for gRPC
public final class GRPCInterfaceExporter: Configuration {
    let configuration: GRPCExporterConfiguration
    let staticConfigurations: [GRPCDependentStaticConfiguration]
    
    public init(integerWidth: IntegerWidthConfiguration = .native,
                @GRPCDependentStaticConfigurationBuilder staticConfigurations:
                    () -> [GRPCDependentStaticConfiguration] = { [EmptyGRPCDependentStaticConfiguration()] }) {
        self.configuration = GRPCExporterConfiguration(integerWidth: integerWidth)
        self.staticConfigurations = staticConfigurations()
    }
    
    public func configure(_ app: Apodini.Application) {
        /// Instanciate exporter
        let grpcExporter = _GRPCInterfaceExporter(app, self.configuration)
        
        /// Insert exporter into `SemanticModelBuilder`
        let builder = app.exporters.semanticModelBuilderBuilder
        app.exporters.semanticModelBuilderBuilder = { model in
            builder(model).with(exporter: grpcExporter)
        }
        
        /// Configure attached related static configurations
        self.staticConfigurations.configure(app, parentConfiguration: self.configuration)
    }
}

/// Internal Apodini Interface Exporter for gRPC
// swiftlint:disable type_name
final class _GRPCInterfaceExporter: InterfaceExporter {
    let app: Apodini.Application
    let exporterConfiguration: GRPCExporterConfiguration
    var services: [String: GRPCService]
    var parameters: [UUID: Int]

    /// Initalize `GRPCInterfaceExporter` from `Application`
    init(_ app: Apodini.Application,
         _ exporterConfiguration: GRPCExporterConfiguration = GRPCExporterConfiguration()) {
        self.app = app
        self.exporterConfiguration = exporterConfiguration
        self.services = [:]
        self.parameters = [:]
    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        let serviceName = gRPCServiceName(from: endpoint)
        let methodName = gRPCMethodName(from: endpoint)

        // generate and store the field tags for all parameters
        // of this endpoint
        endpoint.parameters
            .enumerated()
            .forEach { param in
                self.parameters[param.element.id] = param.offset + 1
            }

        // expose the new component via a GRPCService
        // currently unary enpoints are considered here
        let service: GRPCService
        if let existingService = services[serviceName] {
            service = existingService
        } else {
            service = GRPCService(name: serviceName, using: app, self.exporterConfiguration)
            services[serviceName] = service
        }

        let context = endpoint.createConnectionContext(for: self)

        do {
            let serviceType = endpoint[ServiceType.self]
            if serviceType == .unary {
                try service.exposeUnaryEndpoint(name: methodName, context: context)
                app.logger.info("Exported unary gRPC endpoint \(serviceName)/\(methodName)")
            } else if serviceType == .clientStreaming {
                try service.exposeClientStreamingEndpoint(name: methodName, context: context)
                app.logger.info("Exported client-streaming gRPC endpoint \(serviceName)/\(methodName)")
            } else {
                // Service-side streaming (and as a consequence also bidirectional streaming)
                // are not yet supporter.
                // Refer to issue #142: https://github.com/Apodini/Apodini/issues/142
                app.logger.warning("""
                    GRPC exporter currently only supports unary and client-streaming endpoints.
                    Defaulting to unary.
                    Exported unary gRPC endpoint \(serviceName)/\(methodName).
                    """)
                try service.exposeUnaryEndpoint(name: methodName, context: context)
            }

            app.logger.info("\tParameters:")
            for parameter in endpoint.parameters {
                app.logger.info("\t\t\(parameter.propertyType) \(parameter.name) = \(getFieldTag(for: parameter) ?? 0);")
            }
        } catch GRPCServiceError.endpointAlreadyExists {
            app.logger.error("Tried to overwrite endpoint \(methodName) for gRPC service \(serviceName)")
        } catch {
            app.logger.error("Error while exporting endpoint \(methodName) for gRPC service \(serviceName): \(error)")
        }
    }

    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: GRPCMessage) throws -> Type?? {
        guard let fieldTag = getFieldTag(for: parameter) else {
            // If this occurs, something went fundamentally wrong in usage
            // of the GRPC exporter.
            // Each parameter should get a default field tag assigned
            // above in the export() funtction.
            fatalError("No default or explicit field tag available")
        }

        if request.data.isEmpty {
            throw GRPCError.decodingError("""
                No body data available to decode.
                GRPC exporter expects all parameters to be in the body of the request.
                """)
        }

        do {
            // we need to wrap the type into a struct to
            // actually have a messsage.
            let wrappedType = RequestWrapper<Type>.self
            // set the fieldNumber to the one annotated at the
            // parameter, or use default interference if none is
            // annotated at the parameter.
            FieldNumber.setFieldNumber(fieldTag)

            let decoder = ProtobufferDecoder()
            
            switch self.exporterConfiguration.integerWidth {
            case .thirtyTwo:
                decoder.integerWidthCodingStrategy = .thirtyTwo
            case .sixtyFour:
                decoder.integerWidthCodingStrategy = .sixtyFour
            }

            let wrappedDecoded = try decoder.decode(wrappedType, from: request.data)
            return wrappedDecoded.request
        } catch {
            // Decoding fails if the parameter is not present
            // in the payload.
            // Not-presence of non-optional parameters is
            // handled in shared model, so we do not care here.
            return nil
        }
    }
}

// MARK: Parameter retrieval utility

extension _GRPCInterfaceExporter {
    /// Retrieves explicitly provided Protobuffer field tag, if exists,
    /// or uses default field tag that was generated in `export()`.
    /// - Parameter parameter: The `AnyEndpointParameter` to get the Protobuffer field-tag for.
    private func getFieldTag(for parameter: AnyEndpointParameter) -> Int? {
        parameter.option(for: .gRPC)?.fieldNumber ?? parameters[parameter.id]
    }
}

extension GRPCParameterOptions {
    /// Extracts the Protobuffer field-number from the
    /// `GRPCParameterOptions` instance.
    public var fieldNumber: Int {
        switch self {
        case let .fieldTag(number):
            return number
        }
    }
}

/// Used to wrap top-level primitive types before decoding.
/// ProtoDecoder needs to get a message type, which is a struct in Swift case.
private struct RequestWrapper<T>: Decodable where T: Decodable {
    /// The value that is wrapped in this struct
    /// and should be decoded from the data.
    var request: T

    enum CodingKeys: String, CodingKey, ProtobufferCodingKey {
        case request
        /// Always returns the public `fieldNumber`.
        /// This is needed to be able to influence the field-number
        /// of the wrapped value "from the outside".
        /// It is used by the `GRPCRequest`s decode function,
        /// to consider field-numbers that the Apodini
        /// user applied via the `@Parameter` options.
        var protoRawValue: Int {
            FieldNumber.getFieldNumber()
        }
    }
}

/// Used by the `RequestWrapper` as the
/// `ProtoCodingKey` for the wrapped value
/// that should be decoded. Default is 1.
/// Each thread needs its own field-number, because we might
/// be decoding multiple requests at the same time.
private var fieldNumber = ThreadSpecificVariable<FieldNumber>()

final class FieldNumber {
    private var tag = 1

    /// Returns the field-number for the current thread.
    static func getFieldNumber() -> Int {
        if let singleton = fieldNumber.currentValue {
            return singleton.tag
        }
        let newFieldNumber = FieldNumber()
        fieldNumber.currentValue = newFieldNumber
        return newFieldNumber.tag
    }

    /// Sets the field-number for the current thread.
    static func setFieldNumber(_ number: Int) {
        if fieldNumber.currentValue != nil {
            fieldNumber.currentValue?.tag = number
        } else {
            let newFieldNumber = FieldNumber()
            newFieldNumber.tag = number
            fieldNumber.currentValue = newFieldNumber
        }
    }
}
