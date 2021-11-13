//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import ApodiniExtension
import ApodiniHTTPProtocol
import NIO
import NIOHTTP1
import ApodiniLoggingSupport
import Foundation


extension HTTPRequest {
    struct InformationEntryHTTPVersion: Apodini.Information {
        struct Key: InformationKey { // swiftlint:disable nesting
            typealias RawValue = HTTPVersion
            static let shared = Key("requestHTTPVersion")
            let key: String
            init(_ key: String) {
                self.key = key
            }
        }
        
        var key: Key { .shared }
        let value: HTTPVersion
        
        init(key: Key, rawValue: HTTPVersion) {
            precondition(key == Key.shared, "Unexpected key value")
            self.value = rawValue
        }
    }
}


/// A HTTP request
public final class HTTPRequest: RequestBasis, Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    struct ParametersStorage: Hashable {
        /// The request's parameters that are expressed via a clear key-value mapping (e.g.: explicitly named path parameters)
        var namedParameters: [String: String] = [:]
        /// The request's parameters that are the result from matching the request against a ``HTTPRouter.Route`` which contained single-path-component wildcards
        /// key: index of wildcard in path components array
        var singleComponentWildcards: [Int: String] = [:]
        /// The request's parameters that are the result from matching the request against a ``HTTPRouter.Route`` which contained multi-path-component wildcards
        /// key: index of wildcard in path components array
        var multipleComponentWildcards: [Int: [String]] = [:]
    }
    
    
    public let remoteAddress: SocketAddress?
    public let version: HTTPVersion
    public let method: HTTPMethod
    public let url: URI
    public var headers: HTTPHeaders
    public var bodyStorage: BodyStorage
    public let eventLoop: EventLoop
    
    /// For incoming requests from external clients processed through the HTTP server's router, the route this request matched against.
    /// - Note: This property is `nil` for manually constructed requests
    internal var route: HTTPRouter.Route?
    
    private var parameters = ParametersStorage()
    
    
    public init(
        remoteAddress: SocketAddress? = nil,
        version: HTTPVersion = .http1_1,
        method: HTTPMethod,
        url: URI,
        headers: HTTPHeaders = [:],
        bodyStorage: BodyStorage = .buffer(),
        eventLoop: EventLoop
    ) {
        self.remoteAddress = remoteAddress
        self.version = version
        self.method = method
        self.url = url
        self.headers = headers
        self.bodyStorage = bodyStorage
        self.eventLoop = eventLoop
    }
    
    public var information: InformationSet {
        InformationSet(headers.map { key, rawValue in
            AnyHTTPInformation(key: key, rawValue: rawValue)
        })
            .merge(with: [
                InformationEntryHTTPVersion(key: .shared, rawValue: version)
            ])
            .merge(with: self.loggingMetadata)
    }
    
    public var description: String {
        "<\(Self.self) \(version.description) \(method.rawValue) \(url.stringValue)>"
    }
    
    public var debugDescription: String {
        self.description
    }
    
    
    var loggingMetadata: [LoggingMetadataInformation] {
        var metadata: [LoggingMetadataInformation] = [
            LoggingMetadataInformation(
                key: .init("ApodiniNetworkingRequestDescription"),
                rawValue: .string(self.description)
            ),
            LoggingMetadataInformation(
                key: .init("HTTPContentType"),
                rawValue: .string(self.headers[.contentType]?.encodeToHTTPHeaderFieldValue() ?? "unknown")
            ),
            LoggingMetadataInformation(
                key: .init("HTTPVersion"),
                rawValue: .string(self.version.description)
            ),
            LoggingMetadataInformation(
                key: .init("url"),
                rawValue: .string(self.url.stringValue)
            ),
            LoggingMetadataInformation(
                key: .init("url.path"),
                rawValue: .string(self.url.path)
            ),
            LoggingMetadataInformation(
                key: .init("url.pathAndQuery"),
                rawValue: .string(self.url.pathIncludingQueryAndFragment)
            ),
         ]
        switch bodyStorage {
        case .buffer(let buffer):
            metadata.append(LoggingMetadataInformation(
                key: .init("HTTPBody"),
                rawValue: .string(buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes > 8_192 ? 8_192 : buffer.readableBytes) ?? "HTTP body couldn't be read")
            ))
        case .stream(let stream):
            if let buffer = stream.readNewData() {
                metadata.append(LoggingMetadataInformation(
                    key: .init("HTTPBody"),
                    rawValue: .string(buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes > 8_192 ? 8_192 : buffer.readableBytes) ?? "HTTP body couldn't be read")
                ))
            } else {
                metadata.append(LoggingMetadataInformation(
                    key: .init("HTTPBody"),
                    rawValue: .string("")
                ))
            }
        }
        if let route = route {
            metadata.append(LoggingMetadataInformation(
                key: .init("route"),
                rawValue: .string("\(route.method) \(route.path.httpPathString)")
            ))
        }
        return metadata
    }
    
    /// Read a query param value, decoded to the specified type.
    /// - Note: This function adopts Apodini's requirement that only types conforming to the `LosslessStringConvertible` protocol may be used as query parameters.
    ///         It may work with other types, but that's really just by accident.
    public func getQueryParam<T: Decodable>(for key: String, as _: T.Type = T.self) throws -> T? {
        guard case Optional<String?>.some(.some(let rawValue)) = url.queryItems[key] else { // swiftlint:disable:this syntactic_sugar
            return nil
        }
        return try URLQueryParameterValueDecoder().decode(T.self, from: rawValue)
    }
    
    /// Returns the raw (i.e. stringly typed) value of the specified non-query parameter
    public func getParameterRawValue(_ name: String) -> String? {
        // Note what about values matched to wildcards? Do these ever get accessed?
        parameters.namedParameters[name]
    }
    
    /// Returns the value of the specified non-query parameter, decoded using the specified type
    public func getParameter<T: Decodable>(_ name: String, as _: T.Type = T.self) throws -> T? {
        guard let rawValue = getParameterRawValue(name) else {
            return nil
        }
        return try JSONDecoder().decode(T.self, from: rawValue.data(using: .utf8)!)
    }
    
    
    /// Adds a non-query parameter to the request
    public func setParameter(for key: String, to value: String?) {
        parameters.namedParameters[key] = value?.removingPercentEncoding
    }
    
    internal func populate(from route: HTTPRouter.Route, withParameters parameters: ParametersStorage) {
        self.route = route
        self.parameters = parameters
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    public static func == (lhs: HTTPRequest, rhs: HTTPRequest) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
