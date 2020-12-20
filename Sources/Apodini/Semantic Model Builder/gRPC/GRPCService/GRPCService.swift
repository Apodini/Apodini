//
//  GRPCService.swift
//
//
//  Created by Moritz Schüll on 05.12.20.
//

import Foundation
@_implementationOnly import Vapor
@_implementationOnly import GRPC
import ProtobufferCoding

/// Used by the `GRPCSemanticModelBuilder` to expose
/// `handle` functions of `Components`.
class GRPCService {
    private let supportedTypes: [Any.Type] = [
        String.self,
        Int32.self,
        Int64.self,
        UInt32.self,
        UInt64.self,
        Double.self,
        Float.self
    ]

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

// MARK: Processing guards
extension GRPCService {
    func processGuards(_ request: Request, with context: Context) -> [EventLoopFuture<Void>] {
        return context.get(valueFor: GuardContextKey.self)
            .map { requestGuard in
                request.enterRequestContext(with: requestGuard()) { requestGuard in
                    requestGuard.executeGuardCheck(on: request)
                }
            }
    }
}

// MARK: Encoding response
extension GRPCService {
    fileprivate struct ResponseWrapper<T>: Encodable where T: Encodable {
        var response: T
    }

    /// Tests whther the given value is
    /// a collection.
    /// - returns True if the given value is a collection, else False
    private func isCollection(_ any: Any) -> Bool {
        let m = Mirror(reflecting: any)
        switch m.displayStyle {
        case .some(.collection):
            return true
        default:
            return false
        }
    }

    /// Encodes the given encodable value
    /// to  `Data` using Protobuffer encoding
    private func encode<T: Encodable>(_ value: T) throws -> Data {
        let message: Data
        if supportedTypes.contains(where: { $0 == T.self }) ||
            isCollection(value) {
            // if value is not a complex type
            // (either only a primitive type or a collection),
            // we need to wrap it into a struct to
            // actually have a messsage
            let wrapped = ResponseWrapper(response: value)
            message = try ProtoEncoder().encode(wrapped)
        } else {
            message = try ProtoEncoder().encode(value)
        }
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
    func encodeResponse<T: Encodable>(_ value: T) -> Vapor.Response {
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
