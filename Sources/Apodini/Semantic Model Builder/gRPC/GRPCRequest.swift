//
//  GRPCRequest.swift
//
//
//  Created by Moritz Schüll on 05.12.20.
//

import Foundation
import ProtobufferCoding
@_implementationOnly import Vapor
import protocol Fluent.Database

/// Used to wrap top-level primitive types before decoding.
/// ProtoDecoder needs to get a message type, which is a struct in Swift case.
private struct RequestWrapper<T>: Decodable where T: Decodable {
    var request: T
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
