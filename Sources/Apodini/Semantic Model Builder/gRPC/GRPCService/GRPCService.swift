//
//  GRPCService.swift
//
//
//  Created by Moritz Schüll on 05.12.20.
//

import Foundation
@_implementationOnly import Vapor
@_implementationOnly import ProtobufferCoding
@_implementationOnly import OpenCombine

/// Used by the `GRPCInterfaceExporter` to expose
/// `handle` functions of `Handler`s.
class GRPCService {
    let app: Vapor.Application
    var serviceName: String
    var methodNames: [String] = []

    internal var cancellables: Set<AnyCancellable> = []

    /// GRPC media type, with unspecified payload encoding
    static let grpc = HTTPMediaType(type: "application", subType: "grpc")
    /// GRPC media type, with Protobuffer payload encoding
    static let grpcproto = HTTPMediaType(type: "application", subType: "grpc+proto")

    /// Initializes a new GRPC service.
    /// - Parameters:
    ///     - name: The name of the service. Will be part of the route at which the service is exposed.
    ///     - handler: The handler method that executes the guards, component's handle method, and modifiers.
    init(name: String, using app: Application) {
        self.serviceName = name
        self.app = app.vapor.app
    }

    internal func contentTypeIsSupported(request: Vapor.Request) -> Bool {
        // GRPC theoretically would also allow for other
        // types of payload formats, e.g. JSON.
        // We only support proto payloads at the moment
        request.content.contentType == Self.grpc || request.content.contentType == Self.grpcproto
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

        while data.count > 5 {
            // https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-HTTP2.md
            // A message is prefixed by
            // - 1 byte:    compressed (true / false)
            // - 4 bytes:   big-endian; length of message
            let compressed = data.popFirst()
            let lengthBytes = [UInt8](data.prefix(4))
            let ulength = lengthBytes.reduce(0) { result, new in
                result << 8 | UInt32(new)
            }
            let length = Int(ulength)

            // remove the length bytes
            data = data.advanced(by: 4)

            if data.count >= length {
                // There is more data left than the message is long and a second
                // message is to follow,
                // or there is all the data available that belongs to this message,
                // and no other message follows in the given data.
                let messageData = data.subdata(in: 0..<length)
                messages.append(GRPCMessage(from: messageData, length: length, compressed: compressed == 1))
                // remove the bytes of this message
                data = data.dropFirst(length)
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
        }
        return messages
    }
}

// MARK: Encoding response
extension GRPCService {
    /// Encodes the given encodable value
    /// to  `Data` using Protobuffer encoding
    func encode(_ value: Encodable) -> Data? {
        do {
            let message = try ProtobufferEncoder().encode(AnyEncodable(value))
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
        } catch {
            app.logger.error("Error while encoding response: \(error)")
        }
        return nil
    }

    /// Builds a `Vapor.Response` from the given body stream writer.
    func makeResponse(_ stream: @escaping (BodyStreamWriter) -> Void) -> Vapor.Response {
        var headers = HTTPHeaders()
        headers.contentType = Self.grpcproto
        return Vapor.Response(status: .ok,
                              version: HTTPVersion(major: 2, minor: 0),
                              headers: headers,
                              body: .init(stream: stream))
    }
}
