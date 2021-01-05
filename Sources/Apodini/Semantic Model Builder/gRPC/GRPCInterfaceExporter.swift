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
        var serviceName = endpoint.context.get(valueFor: GRPCServiceNameContextKey.self)
        // if no explicit servicename is provided via the modifier,
        // simply use the PathComponents to come up with one
        if serviceName == GRPCServiceNameContextKey.defaultValue {
            let components = endpoint.context.get(valueFor: PathComponentContextKey.self)
            let builder = StringPathBuilder(components, delimiter: "")
            serviceName = builder.build()
        }

        var methodName = endpoint.context.get(valueFor: GRPCMethodNameContextKey.self)
        // if no explicit methodname is provided via the modifier,
        // we have to rely on the component name
        if methodName == GRPCMethodNameContextKey.defaultValue {
            methodName = "\(H.self)".lowercased()
        }

        // generate default field tags for all parameters
        // by enumerating them (proto field tags start from 1)
        // Note: because the order at which the parameters are received
        // is not stable, this is sorting the parameters by name (alphabetically)
        // as a work-aorund to establish reproducable default field tags.
        endpoint.exportParameters(on: self)
            .sorted(by: { left, right in left.0 < right.0 }) // sort by name
            .map { $0.1 }  // only keep the UUIDs
            .enumerated()   // enumerate to create default field tags
            .forEach { item in
                self.parameters[item.element] = item.offset + 1
            }

        let context = endpoint.createConnectionContext(for: self)

        // expose the new component via a GRPCService
        // currently unary enpoints are considered here
        if let service = services[serviceName] {
            service.exposeUnaryEndpoint(name: methodName, context: context)
        } else {
            let service = GRPCService(name: serviceName, using: app)
            service.exposeUnaryEndpoint(name: methodName, context: context)
            services[serviceName] = service
        }
        
        app.logger.info("Exported gRPC endpoint \(serviceName)/\(methodName) with parameters:")
        for parameter in endpoint.parameters {
            app.logger.info("\t\(parameter.propertyType) \(parameter.name) = \(getFieldTag(for: parameter) ?? 0);")
        }
    }

    func exportParameter<Type: Codable>(_ parameter: EndpointParameter<Type>) -> (String, UUID) {
        (parameter.name, parameter.id)
    }

    /// The GRPC exporter handles all parameters equally as body parameters
    func retrieveParameter<Type: Decodable>(_ parameter: EndpointParameter<Type>, for request: Vapor.Request) throws -> Type?? {
        let contentType = request.headers.first(name: .contentType)
        switch contentType {
        case "application/grpc", "application/grpc+proto":
            guard let fieldTag = getFieldTag(for: parameter) else {
                // If this occurs, something went fundamentally wrong in usage
                // of the GRPC exporter.
                // Each parameter should get a default field tag assigned
                // above in the export() funtction.
                fatalError("No default or explicit field tag available")
            }
            guard let data = bodyData(from: request) else {
                throw GRPCError.decodingError("""
                    No body data available to decode from.
                    GRPC exporter expects all parameters to be in the body of the request.
                    """)
            }

            do {
                let result: Type = try decodeParameter(from: data, with: fieldTag)
                return result
            } catch {
                // Decoding fails if the parameter is not present
                // in the payload.
                // Not-presence of non-optional parameters is
                // handled in shared model, so we do not care here.
                return nil
            }
        default:
            // GRPC theoretically would also allow for other
            // types of payload formats, e.g. JSON.
            throw GRPCError.unsupportedContentType(
                "Content type \(contentType ?? "") is currently not supported by Apodini GRPC exporter"
            )
        }
    }
}

// MARK: Parameter retrieval utility

extension GRPCInterfaceExporter {
    /// Returns the data contained in the body of the GRPC request.
    private func bodyData(from request: Vapor.Request) -> Data? {
        guard let byteBuffer = request.body.data else {
            print("Cannot read body data.")
            return nil
        }
        return byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes)
    }

    /// Retrieves explicitly provided Protobuffer field tag, if exists,
    /// or uses default field tag that was generated in `export()`.
    /// - Parameter parameter: The `AnyEndpointParameter` to get the Protobuffer field-tag for.
    private func getFieldTag(for parameter: AnyEndpointParameter) -> Int? {
        parameter.options.option(for: .gRPC)?.fieldNumber ?? parameters[parameter.id]
    }

    private func decodeParameter<T: Decodable>(from data: Data, with fieldTag: Int) throws -> T {
        // data has to be longer than 5 bytes, because
        // the first 5 bytes are prefix (see comment below)
        if data.count <= 5 {
            throw GRPCError.decodingError("Data was to short to decode a message from")
        }
        // https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-HTTP2.md
        // A message is prefixed by
        // - 1 byte:    compressed (true / false)
        // - 4 bytes:   big-endian; length of message
        // Hence, we cut those 5 bytes to be able to decode
        // the message itself
        let message = data.subdata(in: 5 ..< data.count)
        // we need to wrap the type into a struct to
        // actually have a messsage.
        let wrappedType = RequestWrapper<T>.self
        // set the fieldNumber to the one annotated at the
        // parameter, or use default interference if none is
        // annotated at the parameter.
        FieldNumber.setFieldNumber(fieldTag)
        let wrappedDecoded = try ProtoDecoder().decode(wrappedType, from: message)
        return wrappedDecoded.request
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
