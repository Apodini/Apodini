//
//  GRPCInterfaceExporter.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import NIO
@_implementationOnly import Vapor
@_implementationOnly import NIOHPACK
@_implementationOnly import ProtobufferCoding

class GRPCInterfaceExporter: InterfaceExporter {
    let app: Application
    var services: [String: GRPCService]
    var parameters: [UUID: Int]

    required init(_ app: Application) {
        self.app = app
        self.services = [:]
        self.parameters = [:]
    }

    func export<H: Handler>(_ endpoint: Endpoint<H>) {
        let serviceName = endpoint.serviceName
        let methodName = endpoint.methodName

        // generate and store the field tags for all parameters
        // of this endpoint
        endpoint.parameters
            .enumerated()
            .forEach { param in
                self.parameters[param.element.id] = param.offset + 1
            }

        let context = endpoint.createConnectionContext(for: self)

        // expose the new component via a GRPCService
        // currently unary enpoints are considered here
        let service: GRPCService
        if let srvc = services[serviceName] {
            service = srvc
        } else {
            service = GRPCService(name: serviceName, using: app)
            services[serviceName] = service
        }

        if endpoint.serviceType == .unary {
            service.exposeUnaryEndpoint(name: methodName, context: context)
            app.logger.info("Exported unary gRPC endpoint \(serviceName)/\(methodName) with parameters:")
        } else if endpoint.serviceType == .clientStreaming {
            service.exposeClientStreamingEndpoint(name: methodName, context: context)
            app.logger.info("Exported client-streaming gRPC endpoint \(serviceName)/\(methodName) with parameters:")
        } else {
            app.logger.warning("""
                GRPC exporter currently only supports unary and client-streaming endpoints.
                Defaulting to unary.
                Exported unary gRPC endpoint \(serviceName)/\(methodName) with parameters:
                """)
            service.exposeUnaryEndpoint(name: methodName, context: context)
        }

        for parameter in endpoint.parameters {
            app.logger.info("\t\(parameter.propertyType) \(parameter.name) = \(getFieldTag(for: parameter) ?? 0);")
        }
    }

    /// The GRPC exporter handles all parameters equally as body parameters
    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: GRPCMessage) throws -> Type?? {
        guard let fieldTag = getFieldTag(for: parameter) else {
            // If this occurs, something went fundamentally wrong in usage
            // of the GRPC exporter.
            // Each parameter should get a default field tag assigned
            // above in the export() funtction.
            fatalError("No default or explicit field tag available")
        }

        if request.data.count == 0 {
            throw GRPCError.decodingError("""
                No body data available to decode from.
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
            let wrappedDecoded = try ProtoDecoder().decode(wrappedType, from: request.data)
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

extension GRPCInterfaceExporter {
    /// Retrieves explicitly provided Protobuffer field tag, if exists,
    /// or uses default field tag that was generated in `export()`.
    /// - Parameter parameter: The `AnyEndpointParameter` to get the Protobuffer field-tag for.
    private func getFieldTag(for parameter: AnyEndpointParameter) -> Int? {
        parameter.options.option(for: .gRPC)?.fieldNumber ?? parameters[parameter.id]
    }
}

extension GRPCParameterOptions {
    /// Extractes the Protobuffer field-number from the
    /// `GRPCParameterOptions` instance.
    var fieldNumber: Int {
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

    enum CodingKeys: String, CodingKey, ProtoCodingKey {
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

class FieldNumber {
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
