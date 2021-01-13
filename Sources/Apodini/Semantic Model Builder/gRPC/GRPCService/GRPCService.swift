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

    internal func checkContentType(request: Vapor.Request) -> Bool {
        let contentType = request.headers.first(name: .contentType)
        switch contentType {
        case "application/grpc", "application/grpc+proto":
            return true
        default:
            // GRPC theoretically would also allow for other
            // types of payload formats, e.g. JSON.
            // We do only support proto payloads at the moment
            return false
        }
    }

    /// Cuts the given data into the individual GRPC messages it represents.
    ///
    /// Cite: https://grpc.io/blog/grpc-on-http2/
    /// "RPCs are in practice plain HTTP/2 streams.
    /// Messages are associated with RPCs and get sent as HTTP/2 data frames.
    /// To be more specific, messages are layered on top of data frames.
    /// A data frame may have many gRPC messages,
    /// or if a gRPC message is quite large it might span multiple data frames."
    ///
    /// - Parameter data: The data to read the GRPC  messages from
    internal func getMessages(from data: Data) -> [GRPCMessage] {
        var data = data
        var messages: [GRPCMessage] = []
        var hasNext = false
        repeat {
            // https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-HTTP2.md
            // A message is prefixed by
            // - 1 byte:    compressed (true / false)
            // - 4 bytes:   big-endian; length of message
            precondition(data.count > 5,
                         "Remaining payload data not long enough to read message from")
            let compressed = data.popFirst() // ignore compressed byte
            let lengthBytes = [UInt8](data.prefix(4))
            let ulength = lengthBytes.reduce(0) { result, new in
                result << 8 | UInt32(new)
            }
            let length = Int(ulength)

            // remove the length bytes
            data = data.advanced(by: 4)

            if data.count > length {
                // There is more data left than the message is long.
                // So a second message is to follow
                hasNext = true
                let messageData = data.subdata(in: 0..<length)
                messages.append(GRPCMessage(from: messageData, length: length, compressed: compressed == 1))
                // remove the bytes of this message
                data = data.advanced(by: length)
            } else if data.count == length {
                // There is all the data available that belongs to this message,
                // and no other message follows in the given data.
                hasNext = false
                messages.append(GRPCMessage(from: data, length: length, compressed: compressed == 1))
            } else {
                // data.count < length:
                // There is not all the data that belongs to this message
                // in this data object. The remainder will be delivered with
                // the next frame.
                //
                // This is currently not supported.
                // See GitHub issue #127: https://github.com/Apodini/Apodini/issues/127
                fatalError("Apodini GRPC exporter does not yet support messages spanning multiple HTTP frames")
            }
        } while hasNext
        return messages
    }
}

// MARK: Encoding response
extension GRPCService {
    /// Encodes the given encodable value
    /// to  `Data` using Protobuffer encoding
    private func encode(_ value: Encodable) throws -> Data {
        let message = try ProtoEncoder().encode(AnyEncodable(value))
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

    /// Builds a `Vapor.Response` with an empty payload.
    func makeResponse() -> Vapor.Response {
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/grpc+proto")
        return Vapor.Response(status: .internalServerError,
                              version: HTTPVersion(major: 2, minor: 0),
                              headers: headers,
                              body: .init(data: Data()))
    }

    /// Builds a `Vapor.Response` from the given encodable value.
    func makeResponse(_ value: Encodable) -> Vapor.Response {
        do {
            let data = try encode(value)
            var headers = HTTPHeaders()
            headers.add(name: .contentType, value: "application/grpc+proto")
            return Vapor.Response(status: .ok,
                                  version: HTTPVersion(major: 2, minor: 0),
                                  headers: headers,
                                  body: .init(data: data))
        } catch {
            app.logger.report(error: error)
            return makeResponse()
        }
    }
}
