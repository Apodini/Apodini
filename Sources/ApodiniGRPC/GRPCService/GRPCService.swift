//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import NIO
import Apodini
import ApodiniUtils
@_implementationOnly import ProtobufferCoding
import ApodiniNetworking


extension HTTPMediaType {
    /// gRPC media type subtype suffix options
    enum GRPCEncodingOption: String {
        case proto
        case json
    }
    
    /// Creates a gRPC media type with the specified encoding appended as the subtype's suffix
    static func gRPC(_ encoding: GRPCEncodingOption) -> HTTPMediaType {
        HTTPMediaType(type: "application", subtype: "grpc+\(encoding.rawValue)")
    }
    
    /// The `application/grpc` media type without an explicitly specified encoding
    static let gRPCPlain = HTTPMediaType(type: "application", subtype: "grpc")
}


/// Used by the `GRPCInterfaceExporter` to expose
/// `handle` functions of `Handler`s.
class GRPCService {
    let app: Apodini.Application
    private let exporterConfiguration: GRPC.ExporterConfiguration
    
    var serviceName: String
    var methodNames: [String] = []

    /// Initializes a new GRPC service.
    /// - Parameters:
    ///     - name: The name of the service. Will be part of the route at which the service is exposed.
    ///     - app: The current Apodini application.
    init(name: String, using app: Apodini.Application, _ configuration: GRPC.ExporterConfiguration) {
        self.serviceName = name
        self.app = app
        self.exporterConfiguration = configuration
    }

    internal func contentTypeIsSupported(request: HTTPRequest) -> Bool {
        // GRPC theoretically would also allow for other
        // types of payload formats, e.g. JSON.
        // We only support proto payloads at the moment
        guard let contentType = request.headers[.contentType] else {
            return false
        }
        return contentType == .gRPCPlain || contentType == .gRPC(.proto)
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
    internal func getMessages(from data: Data, remoteAddress: SocketAddress?) -> [GRPCMessage] {
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
                messages.append(GRPCMessage(from: messageData, length: length, compressed: compressed == 1, remoteAddress: remoteAddress))
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
    private func encode(_ value: Encodable) throws -> Data {
        let encoder = ProtobufferEncoder()
        
        switch self.exporterConfiguration.integerWidth {
        case .thirtyTwo:
            encoder.integerWidthCodingStrategy = .thirtyTwo
        case .sixtyFour:
            encoder.integerWidthCodingStrategy = .sixtyFour
        }
            
        let message = try encoder.encode(AnyEncodable(value))
        // https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-HTTP2.md
        // A response is prefixed by
        // - 1 byte:    compressed (true / false)
        // - 4 bytes:   length of the message
        var response = Data()
        var length = Int32(message.count).bigEndian
        let lengthData = Data(bytes: &length, count: 4)
        response.append(UInt8(0))
        response.append(lengthData)
        response.append(message)
        return response
    }

    /// Builds a `Vapor.Response` with an empty payload.
    func makeResponse() -> HTTPResponse {
        HTTPResponse(
            version: .http2,
            status: .internalServerError,
            headers: HTTPHeaders { $0[.contentType] = .gRPC(.proto) },
            bodyStorage: .buffer()
        )
    }

    /// Builds a `Vapor.Response` from the given encodable value.
    func makeResponse(_ value: Encodable) -> HTTPResponse {
        do {
            return HTTPResponse(
                version: .http2,
                status: .ok,
                headers: HTTPHeaders { $0[.contentType] = .gRPC(.proto) },
                bodyStorage: .buffer(initialValue: try encode(value))
            )
        } catch {
            app.logger.error("Error: \(error)")
            return makeResponse()
        }
    }
}
