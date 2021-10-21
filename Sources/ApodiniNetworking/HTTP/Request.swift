import Apodini
import ApodiniExtension
import ApodiniHTTPProtocol
import NIO
import NIOHTTP1
import Foundation
@_implementationOnly import struct Vapor.URLEncodedFormDecoder // TODO


extension LKHTTPRequest {
    struct ApodiniRequestInformationEntryHTTPVersion: Apodini.Information {
        struct Key: InformationKey {
            typealias RawValue = HTTPVersion
            let key: String
            init(_ key: String) {
                self.key = key
            }
        }
        
        static let key = Key("requestHTTPVersion")
        
        let key: Key
        let value: HTTPVersion
        
        init(key: Key, rawValue: HTTPVersion) {
            precondition(key == Self.key, "Unexpected key value")
            self.key = key
            self.value = rawValue
        }
    }
}


public final class LKHTTPRequest: RequestBasis, CustomStringConvertible, CustomDebugStringConvertible {
    struct ParametersStorage: Hashable {
        /// The requst's parameters that are expressed via a clear key-value mapping (e.g.: explicitly named path parameters)
        var namedParameters: [String: String] = [:]
        /// The request's parameters that are the result from matching the request againat a ``LKHTTPRouter.Route`` which contained single-path-component wildcards
        /// key: index of wildcard in path components array
        var singleComponentWildcards: [Int: String] = [:]
        /// The request's parameters that are the result from matching the request againat a ``LKHTTPRouter.Route`` which contained multi-path-component wildcards
        /// key: index of wildcard in path components array
        var multipleComponentWildcards: [Int: [String]] = [:]
    }
    
    
    public let remoteAddress: SocketAddress?
    public let version: HTTPVersion
    public let method: HTTPMethod
    public let url: LKURL
    public var headers: HTTPHeaders
    public var bodyStorage: LKRequestResponseBodyStorage
    public let eventLoop: EventLoop
    
    /// For incoming requests from external clients processed through the HTTP server's router, the route this request matched against.
    /// - Note: This property is `nil` for manually constructed requests
    internal var route: LKHTTPRouter.Route?
    
    private var parameters = ParametersStorage()
    
    
    public init(
        remoteAddress: SocketAddress? = nil,
        version: HTTPVersion = .http1_1,
        method: HTTPMethod,
        url: LKURL,
        headers: HTTPHeaders = [:],
        bodyStorage: LKRequestResponseBodyStorage = .buffer(),
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
        })//.merge(with: self.loggingMetadata) // TODO
            .merge(with: [
                ApodiniRequestInformationEntryHTTPVersion(key: ApodiniRequestInformationEntryHTTPVersion.key, rawValue: version)
            ])
    }
    
    public var description: String {
        return "\(Self.self)(TODO)"
    }
    
    public var debugDescription: String {
        return self.description
    }
    
    // TODO
//    var loggingMetadata: [LoggingMetadataInformation] {
//         [
//            LoggingMetadataInformation(key: .init("VaporRequestDescription"), rawValue: .string(self.description)),
//            LoggingMetadataInformation(key: .init("HTTPBody"), rawValue: .string(self.bodyData.count < 32_768 ? String(decoding: self.bodyData, as: UTF8.self) : "\(String(decoding: self.bodyData, as: UTF8.self).prefix(32_715))... (further bytes omitted since HTTP body too large!")),
//            LoggingMetadataInformation(key: .init("HTTPContentType"), rawValue: .string(self.content.contentType?.description ?? "unknown")),
//            LoggingMetadataInformation(key: .init("hasSession"), rawValue: .string(self.hasSession.description)),
//            LoggingMetadataInformation(key: .init("route"), rawValue: .string(self.route?.description ?? "unknown")),
//            LoggingMetadataInformation(key: .init("HTTPVersion"), rawValue: .string(self.version.description)),
//            LoggingMetadataInformation(key: .init("url"), rawValue: .string(self.url.description))
//         ]
//    }
    
    public func getQueryParam<T: Decodable>(for key: String, as _: T.Type = T.self) throws -> T? {
        // TODO cache these? Apodini probably already does that so there's probably no need to duplicate this...
        // TODO does Apodini handle stuff such as turning non-existent query params into empty strings if requested?
        guard case Optional<String?>.some(.some(let rawValue)) = url.queryItems[key] else {
            return nil
        }
        return try URLEncodedFormDecoder().decode(T.self, from: rawValue)
//        //print(try? try URLEncodedFormDecoder().decode(T.self, from: rawValue), T.self is String.Type, "-[\(Self.self) \(#function)]<\(T.self)>(key='\(key)') value: \(rawValue)")
//        if T.self == String.self {
//            // TODO we have to decode the url-encoded (but not explicitly quoted) string query param into a normal string
//            return (rawValue.removingPercentEncoding! as! T)
//        }
//        return try JSONDecoder().decode(T.self, from: rawValue.data(using: .utf8)!)
    }
    
    /// Returns the raw (i.e. stringly typed) value of the specified non-query parameter
    public func getParameterRawValue(_ name: String) -> String? {
        // TODO what about values matched to wildcards? Do these ever get accessed?
        return parameters.namedParameters[name]
    }
    
    /// Returns the value of the specified non-query parameter, decoded using the specified type
    public func getParameter<T: Decodable>(_ name: String, as _: T.Type = T.self) throws -> T? {
        guard let rawValue = getParameterRawValue(name) else {
            return nil
        }
        return try JSONDecoder().decode(T.self, from: rawValue.data(using: .utf8)!)
    }
    
    // TODO relax this and also allow non-string params? kinda like how we also allow non-string types when retrieving params...
    /// Adds a non-query parameter to the request
    public func setParameter(for key: String, to value: String?) {
        parameters.namedParameters[key] = value?.removingPercentEncoding // Doing the removePErcentEncoding to match Vapor's behaviour. TODO is this correct?
    }
    
    internal func populate(from route: LKHTTPRouter.Route, withParameters parameters: ParametersStorage) {
        self.route = route
        self.parameters = parameters
    }
}

