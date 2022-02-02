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
        enum WildcardKey: Hashable {
            case named(String)
            case unnamed(Int)
        }
        /// The request's parameters that are expressed via a clear key-value mapping (e.g.: explicitly named path parameters)
        var namedParameters: [String: String] = [:]
        /// The request's parameters that are the result from matching the request against a ``HTTPRouter.Route`` which contained single-path-component wildcards
        /// key: wildcard key, which is eiter a string (if the wildcards pat component this was matched to was named),
        /// or an int (if it was unnamed) representing the index of w/in the pats components array
        var singleComponentWildcards: [WildcardKey: String] = [:]
        /// The request's parameters that are the result from matching the request against a ``HTTPRouter.Route`` which contained multi-path-component wildcards
        /// key: wildcard key, which is eiter a string (if the wildcards pat component this was matched to was named),
        /// or an int (if it was unnamed) representing the index of w/in the pats components array
        var multipleComponentWildcards: [WildcardKey: [String]] = [:]
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
    /// - Note: This property is intentionally not a `HTTPRouter.Route`, since that would entail also storing the route's responder, which would introduce the possibility of retain cycles.
    internal var matchedRoute: (method: HTTPMethod, path: [HTTPPathComponent])?
    
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
            )
        ]
        switch bodyStorage {
        case .buffer(let buffer):
            metadata.append(LoggingMetadataInformation(
                key: .init("HTTPBody"),
                rawValue: .string(buffer.getString(
                    at: buffer.readerIndex,
                    length: buffer.readableBytes > 32_768 ? 32_768 : buffer.readableBytes
                ) ?? "HTTP body couldn't be read")
            ))
        case .stream(let stream):
            if let buffer = stream.getNewData() {
                metadata.append(LoggingMetadataInformation(
                    key: .init("HTTPBody"),
                    rawValue: .string(buffer.getString(
                        at: buffer.readerIndex,
                        length: buffer.readableBytes > 32_768 ? 32_768 : buffer.readableBytes
                    ) ?? "HTTP body couldn't be read")
                ))
            } else {
                metadata.append(LoggingMetadataInformation(
                    key: .init("HTTPBody"),
                    rawValue: .string("")
                ))
            }
        }
        if let matchedRoute = matchedRoute {
            metadata.append(LoggingMetadataInformation(
                key: .init("route"),
                rawValue: .string("\(matchedRoute.method) \(matchedRoute.path.httpPathString)")
            ))
        }
        return metadata
    }
    
    /// Read a query param value, decoded to the specified type.
    /// - Note: This function adopts Apodini's requirement that only types conforming to the `LosslessStringConvertible` protocol may be used as query parameters.
    ///         It may work with other types, but that's really just by accident.
    public func getQueryParam<T: Decodable>(
        for key: String,
        as _: T.Type = T.self,
        dateDecodingStrategy: DateDecodingStrategy = .default
    ) throws -> T? {
        guard case Optional<String?>.some(.some(let rawValue)) = url.queryItems[key] else { // swiftlint:disable:this syntactic_sugar
            return nil
        }
        return try URLQueryParameterValueDecoder(dateDecodingStrategy: dateDecodingStrategy).decode(T.self, from: rawValue)
    }
    
    /// Returns the raw (i.e. stringly typed) value of the specified non-query parameter
    public func getParameterRawValue(_ name: String) -> String? {
        // Note what about values matched to wildcards? Do these ever get accessed?
        parameters.namedParameters[name] ?? parameters.singleComponentWildcards[.named(name)]
    }
    
    /// Returns the value of the specified non-query parameter, decoded using the specified type
    public func getParameter<T: Decodable>(
        _ name: String,
        as _: T.Type = T.self,
        dateDecodingStrategy: DateDecodingStrategy = .default
    ) throws -> T? {
        guard let rawValue = getParameterRawValue(name) else {
            return nil
        }
        if T.self == String.self {
            // Going through the decoder would produce the same result, but be significantly slower
            return rawValue as! T?
        }
        do {
            return try URLQueryParameterValueDecoder(dateDecodingStrategy: dateDecodingStrategy).decode(T.self, from: rawValue)
        } catch {
            throw ApodiniNetworkingError(message: "Error decoding parameter '\(name)'", underlying: error)
        }
    }
    
    /// Returns the value of the specified non-query parameter, decoded using the specified type
    public func getMultipleWildcardParameter(named name: String) -> [String]? { // swiftlint:disable:this discouraged_optional_collection
        parameters.multipleComponentWildcards[.named(name)]
    }
    
    
    /// Adds a non-query parameter to the request
    public func setParameter(for key: String, to value: String?) {
        parameters.namedParameters[key] = value?.removingPercentEncoding
    }
    
    internal func populate(from route: HTTPRouter.Route, withParameters parameters: ParametersStorage) {
        self.matchedRoute = (route.method, route.path)
        self.parameters = parameters
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    public static func == (lhs: HTTPRequest, rhs: HTTPRequest) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
