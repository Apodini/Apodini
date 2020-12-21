//
//  GRPCRequest.swift
//
//
//  Created by Moritz Schüll on 05.12.20.
//

import Foundation
import ProtobufferCoding
import NIO
@_implementationOnly import Vapor
import protocol Fluent.Database


/// Used by the `RequestWrapper` as the
/// `ProtoCodingKey` for the wrapped value
/// that should be decoded. Default is 1.
/// Each thread needs its own field-number, because we might
/// be decoding multiple requests at the same time.
private var fieldNumber = ThreadSpecificVariable<FieldNumber>()

class FieldNumber {
    public var tag = 1

    /// Returns the field-number for the current thread.
    public static func getFieldNumber() -> Int {
        if let singleton = fieldNumber.currentValue {
            return singleton.tag
        }
        let newFieldNumber = FieldNumber()
        fieldNumber.currentValue = newFieldNumber
        return newFieldNumber.tag
    }

    /// Sets the field-number for the current thread.
    public static func setFieldNumber(_ number: Int) {
        if fieldNumber.currentValue != nil {
            fieldNumber.currentValue?.tag = number
        } else {
            let newFieldNumber = FieldNumber()
            newFieldNumber.tag = number
            fieldNumber.currentValue = newFieldNumber
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

class GRPCRequest: Apodini.Request {
    /// Supported primitive types of the payload.
    private let supportedTypes: [Any.Type] = [
        String.self,
        Int32.self,
        Int64.self,
        UInt32.self,
        UInt64.self,
        Double.self,
        Float.self
    ]

    /// used for default intereferance of Protobuffer
    /// field-numbers. The first value that is decoded
    /// will be assigned the field-number 1, the second the
    /// field-number 2, and so on.
    /// Default intereference can be overridden using the
    /// `@Parameter` annotation's gRPC options.
    private var decodingCounter = 0

    var eventLoop: EventLoop
    var database: Fluent.Database?
    var description: String
    var body: Vapor.Request.Body
    var headers: HTTPHeaders

    /// Returns the data contained in the body of the GRPC request.
    var bodyData: Data? {
        guard let byteBuffer = body.data else {
            print("Cannot read body data.")
            return nil
        }
        return byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes)
    }

    init(_ vaporRequest: Vapor.Request) {
        self.eventLoop = vaporRequest.eventLoop
        self.database = nil
        self.description = vaporRequest.description
        self.body = vaporRequest.body
        self.headers = vaporRequest.headers
    }

    private func isCollection(_ any: Any) -> Bool {
        switch Mirror(reflecting: any).displayStyle {
        case .some(.collection):
            return true
        default:
            return false
        }
    }

    /// Decodes the payload of the GRPC request.
    /// The payload is decoded using Protobuffers.
    /// If T is a primitive type or a collection,
    /// it will automatically wrapped in a helper struct
    /// (since this is required to decode using ProtoDecoder).
    func parameter<T: Codable>(for parameter: Parameter<T>) throws -> T? {
        decodingCounter += 1
        // data has to be longer than 5 bytes, because
        // the first 5 bytes are prefix (see comment below)
        guard let data = bodyData,
              data.count > 5 else {
            throw GRPCError.decodingError("No body data available to decode from")
        }
        // https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-HTTP2.md
        // A message is prefixed by
        // - 1 byte:    compressed (true / false)
        // - 4 bytes:   big-endian; length of message
        // Hence, we cut those 5 bytes to be able to decode
        // the message itself
        let contentType = headers.first(name: .contentType)
        switch contentType {
        case "application/grpc", "application/grpc+proto":
            let message = data.subdata(in: 5 ..< data.count)
            if supportedTypes.contains(where: { $0 == T.self }) ||
                isCollection(T.self) {
                // if value is not a complex type
                // (either only a primitive type or a collection),
                // we need to wrap it into a struct to
                // actually have a messsage
                let wrappedType = RequestWrapper<T>.self
                // set the fieldNumber to the one annotated at the
                // parameter, or use default interference if none is
                // annotated at the parameter.
                FieldNumber.setFieldNumber(parameter.option(for: .gRPC)?.fieldNumber ?? decodingCounter)
                let wrappedDecoded = try ProtoDecoder().decode(wrappedType, from: message)
                return wrappedDecoded.request
            } else {
                return try ProtoDecoder().decode(T.self, from: message)
            }
        default:
            throw GRPCError.unsupportedContentType(
                "Content type is \(contentType ?? "") is currently not supported by Apodini GRPC implementation"
            )
        }
    }
}
