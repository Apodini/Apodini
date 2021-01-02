//
//  GRPCService.swift
//
//
//  Created by Moritz Schüll on 05.12.20.
//

import Foundation
@_implementationOnly import Vapor
@_implementationOnly import ProtobufferCoding

/// Used by the `GRPCInterfaceExporter` to expose
/// `handle` functions of `Handler`s.
class GRPCService {
    let app: Vapor.Application
    var serviceName: String

    /// Initializes a new GRPC service.
    /// - Parameters:
    ///     - name: The name of the service. Will be part of the route at which the service is exposed.
    ///     - handler: The handler method that executes the guards, component's handle method, and modifiers.
    init(name: String, using app: Vapor.Application) {
        self.serviceName = name
        self.app = app
    }
}

// MARK: Encoding response
extension GRPCService {
    /// Encodes the given encodable value
    /// to  `Data` using Protobuffer encoding
    private func encode(_ value: Encodable) throws -> Data {
        let message = try ProtoEncoder().encode(AnyEncodable(value: value))
        // https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-HTTP2.md
        // A response is prefixed by
        // - 1 byte:    compressed (true / false)
        // - 4 bytes:   length of the message
        var response = Data()
        var length = Int32(message.count).bigEndian
        let lengthData = Data(bytes: &length,
                              count: 4)
        response.append(UInt8(0))
        response.append(lengthData)
        response.append(message)
        return response
    }

    /// Builds a `Vapor.Response` from the given encodable value.
    func encodeResponse(_ value: Encodable) -> Vapor.Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/grpc+proto")
        do {
            let data = try encode(value)
            return Vapor.Response(status: .ok,
                                  version: HTTPVersion(major: 2, minor: 0),
                                  headers: headers,
                                  body: .init(data: data))
        } catch {
            app.logger.report(error: error)
            return Vapor.Response(status: .internalServerError,
                                  version: HTTPVersion(major: 2, minor: 0),
                                  headers: headers,
                                  body: .init(data: Data()))
        }
    }
}
