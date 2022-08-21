//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

@_exported import NIOHTTP1
import NIOHTTP2
@_exported import NIOHPACK
import ApodiniUtils
import Foundation

// swiftlint:disable redundant_string_enum_value


/// A type which represents a HTTP header field value
public protocol HTTPHeaderFieldValueCodable: Hashable {
    /// Attempts to decode the string as a HTTP header value
    init?(httpHeaderFieldValue value: String)
    
    /// Encodes the receiver to a HTTP header value
    func encodeToHTTPHeaderFieldValue() -> String
}


/// A type which represents HTTP1 or HTTP2 headers
public protocol __ANNIOHTTPHeadersType {
    /// Initialises the headers type from a sequence of key-value pairs
    init(_ headers: [(String, String)])
    /// Checks whether at least one header entry exists for the specified key
    func contains(name: String) -> Bool
    /// Adds a header entry
    mutating func add(name: String, value: String, indexing: HPACKIndexing)
    /// Removes a header entry
    mutating func remove(name: String)
    /// Adds a header entry, removing any existing entries with the same key if necessary
    mutating func replaceOrAdd(name: String, value: String, indexing: HPACKIndexing)
    /// Fetches all values for the specified key 
    subscript(name: String) -> [String] { get }
    /// Fetches all key-value entries in this headers data structure
    var entries: [(String, String, HPACKIndexing)] { get } // swiftlint:disable:this large_tuple
}


extension NIOHPACK.HPACKHeaders: __ANNIOHTTPHeadersType {
    public var entries: [(String, String, HPACKIndexing)] { // swiftlint:disable:this large_tuple
        self.map { ($0.name, $0.value, $0.indexable) }
    }
}


extension NIOHTTP1.HTTPHeaders: __ANNIOHTTPHeadersType {
    public mutating func add(name: String, value: String, indexing: HPACKIndexing) {
        add(name: name, value: value)
    }
    
    public mutating func replaceOrAdd(name: String, value: String, indexing: HPACKIndexing) {
        replaceOrAdd(name: name, value: value)
    }
    
    public var entries: [(String, String, HPACKIndexing)] { // swiftlint:disable:this large_tuple
        self.map { ($0.name, $0.value, .indexable) }
    }
}


/// An untyped HTTP/1 or HTTP/2 header key.
public class AnyHTTPHeaderName: Equatable {
    public let rawValue: String
    internal init(_ value: String) {
        self.rawValue = value
    }
    
    public static func == (lhs: AnyHTTPHeaderName, rhs: AnyHTTPHeaderName) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}


/// A typed HTTP (1 or 2) header name, i.e. the key in a header field.
/// - Note: The standard differentiates between single-value and multi-value header fields
///         (i.e. headers which can have only one value, and also appear only once; and headers which can have multiple values and also may appear multiple times).
///         You can control whether a header name defined using this API is a single- or multi-value header by wrapping the header type in an `Array`.
///         For example: `let date = HeaderName<Date>("Date")` defines a single-value header (the Date header may only appear once, and can only contain one value).
///         On the other hand, `let contentEncoding = HeaderName<[HTTPContentEncoding]>("Content-Encoding")` would define a multi-value header, which can contain one or more values, and may also appear multiple times itself.
/// See also: https://datatracker.ietf.org/doc/html/rfc7230#section-3.2
public class HTTPHeaderName<T: HTTPHeaderFieldValueCodable>: AnyHTTPHeaderName {
    override public init(_ value: String) {
        super.init(value)
    }
}


extension __ANNIOHTTPHeadersType {
    /// Initialises a new empty headers struct
    public init() {
        self.init([])
    }
    
    /// Initialises a new headers struct with the specified entries
    public init(_ elements: [(String, String, HPACKIndexing)]) { // swiftlint:disable:this large_tuple
        self.init()
        for (name, value, indexing) in elements {
            add(name: name, value: value, indexing: indexing)
        }
    }
    
    /// Creates a new headers struct, giving the caller the opportunity to initialise it via the closure.
    /// - Note: The reason this initialiser exists is to offer a type-safe way of declaring immutable headers objects.
    ///         The underlying problem here is that Swift doesn't support variadic generics, meaning that (since the type-safe header
    ///         names are implemented via generics) you wouldn't be able to pass more than one generic key-value pair to the initialiser.
    ///         This initialiser works around that by giving the caller the ability to access a mutable version of the headers
    ///         struct (which can be modified using the type-safe API), while still allowing the caller to store the resulting value into an immutable object.
    ///         Since the block is non-escaping, immediately evaluated, and evaluated only once, this is semantically equivalent to declaring a mutable headers object and modifying that.
    public init(_ block: (inout Self) throws -> Void) rethrows {
        self.init([])
        try block(&self)
    }
    
    /// Checks whether at least one entry exists for the specified name
    public func isPresent<T>(_ name: HTTPHeaderName<T>) -> Bool {
        self.contains(name: name.rawValue)
    }
    
    /// Sets the specified value for `name`, if no entry for that key already exists
    public mutating func setUnlessPresent<T: HTTPHeaderFieldValueCodable>(
        name: HTTPHeaderName<T>,
        value: @autoclosure () -> T,
        indexing: HPACKIndexing = .indexable
    ) {
        guard !self.contains(name: name.rawValue) else {
            return
        }
        self.add(name: name.rawValue, value: value().encodeToHTTPHeaderFieldValue(), indexing: indexing)
    }
    
    /// Removes all entries for the specified header name
    public mutating func remove<T>(_ name: HTTPHeaderName<T>) {
        remove(name: name.rawValue)
    }
    
    /// Access a single-value typed header field
    /// - Returns: When reading: `nil` if the field is not present
    /// - Throws: When reading: if the field is present, but there was an error decoding its value. When writing: if there was an error encoding the new value
    /// - Note: Using this subscript to set HTTP2 header values will default the HPACKIndexable property to .indexable. If you don't want this, use the `add` or `replaceOrAdd` functions
    public subscript<T: HTTPHeaderFieldValueCodable>(name: HTTPHeaderName<T>) -> T? {
        get {
            let values = self[name.rawValue]
            precondition(values.count < 2, "Unexpectedly retrieved two or more values for single-value header field '\(name.rawValue)'")
            return values.first.flatMap { T(httpHeaderFieldValue: $0) }
        }
        set {
            if let newValue = newValue {
                self.replaceOrAdd(name: name.rawValue, value: newValue.encodeToHTTPHeaderFieldValue(), indexing: .indexable)
            } else {
                self.remove(name: name.rawValue)
            }
        }
    }
    
    /// Access a multi-value typed header field
    /// - Returns: When reading: `nil` if the field is not present
    /// - Throws: When reading: if the field is present, but there was an error decoding its value. When writing: if there was an error encoding the new value
    /// /// - Note: Using this subscript to set HTTP2 header values will default the HPACKIndexable property to .indexable. If you don't want this, use the `add` or `replaceOrAdd` functions
    public subscript<T: HTTPHeaderFieldValueCodable>(name: HTTPHeaderName<[T]>) -> [T] {
        get {
            switch name {
            case .setCookie:
                // Set-Cookie requires special handling because we can't split or join its values in a comma separator
                return self[name.rawValue].map { T(httpHeaderFieldValue: $0)! }
            default:
                // All other headers can be split on commas
                return self[name.rawValue]
                    .flatMap { $0.split(separator: ",") }
                    .map { $0.trimmingLeadingWhitespace() }
                    .map { T(httpHeaderFieldValue: String($0))! }
            }
        }
        set {
            guard !newValue.isEmpty else {
                remove(name: name.rawValue)
                return
            }
            switch name {
            case .setCookie:
                let encodedValues = newValue.map { $0.encodeToHTTPHeaderFieldValue() }
                for value in encodedValues {
                    add(name: name.rawValue, value: value, indexing: .indexable)
                }
            default:
                add(
                    name: name.rawValue,
                    value: newValue.map { $0.encodeToHTTPHeaderFieldValue() }.joined(separator: ", "),
                    indexing: .indexable
                )
            }
        }
    }
    
    /// Lowercases, in-place, all header names.
    public mutating func lowercaseAllHeaderNames() {
        self = withLowercasedHeaderNames()
    }
    
    /// Returns a copy of the struct where all header names are lowercased
    public func withLowercasedHeaderNames() -> Self {
        Self(entries.map { ($0.lowercased(), $1, $2) })
    }
    
    
    /// Makes, to this headers object, the modificatios required to ensure that they can be handed over to NIO to form a HTTP/2 HEADERS frame
    public mutating func applyHTTP2Validations() {
        self = applyingHTTP2Validations()
    }
    
    /// Returns a copy of this headers object, with HTTP/2 validations applied
    public func applyingHTTP2Validations() -> Self {
        var pseudoHeaderEntries: [(String, String, HPACKIndexing)] = []
        var nonPseudoHeaderEntries: [(String, String, HPACKIndexing)] = []
        for (headerName, headerValue, indexing) in entries {
            if headerName.hasPrefix(":") {
                pseudoHeaderEntries.append((headerName.lowercased(), headerValue, indexing))
            } else {
                nonPseudoHeaderEntries.append((headerName.lowercased(), headerValue, indexing))
            }
        }
        return Self(pseudoHeaderEntries.sorted(by: \.0).appending(contentsOf: nonPseudoHeaderEntries.sorted(by: \.0)))
    }
}


// MARK: List of HTTP Header Names


public extension AnyHTTPHeaderName {
    /// The `Accept` HTTP header field
    static let accept = HTTPHeaderName<[HTTPMediaType]>("Accept")
    /// The `Authorization` HTTP header field
    static let authorization = HTTPHeaderName<AuthorizationHTTPHeaderValue>("Authorization")
    /// The `Connection` HTTP header field
    static let connection = HTTPHeaderName<[HTTPConnectionHeaderValue]>("Connection")
    /// The `Content-Type` HTTP header field
    static let contentType = HTTPHeaderName<HTTPMediaType>("Content-Type")
    /// The `Date` HTTP header field
    static let date = HTTPHeaderName<Date>("Date")
    /// The `Set-Cookie` HTTP header field
    static let setCookie = HTTPHeaderName<[SetCookieHTTPHeaderValue]>("Set-Cookie")
    /// The `Transfer-Encoding` HTTP header field
    static let transferEncoding = HTTPHeaderName<[TransferCodingHTTPHeaderValue]>("Transfer-Encoding")
    /// The `Server` HTTP header field
    static let server = HTTPHeaderName<String>("Server")
    /// The `Upgrade` HTTP header field
    static let upgrade = HTTPHeaderName<[HTTPUpgradeHeaderValue]>("Upgrade")
    /// The `Content-Encoding` HTTP header field
    static let contentEncoding = HTTPHeaderName<[ContentEncodingHTTPHeaderValue]>("Content-Encoding")
    /// The `Content-Length` HTTP header field
    static let contentLength = HTTPHeaderName<Int>("Content-Length")
    /// The `ETag` HTTP header field
    static let eTag = HTTPHeaderName<ETagHTTPHeaderValue>("ETag")
    /// The `Access-Control-Allow-Origin` header field
    static let accessControlAllowOrigin = HTTPHeaderName<AccessControlAllowOriginHeaderValue>("Access-Control-Allow-Origin")
}


public extension AnyHTTPHeaderName {
    /// The HTTP/2 `:method` pseudo header field
    static let methodPseudoHeader = HTTPHeaderName<HTTPMethod>(":method")
    /// The HTTP/2 `:path` pseudo header field
    static let pathPseudoHeader = HTTPHeaderName<String>(":path")
    /// The HTTP/2 `:status` pseudo header field
    static let statusPseudoHeader = HTTPHeaderName<HTTPResponseStatus>(":status")
    /// The HTTP/2 `:authority` pseudo header field
    static let authorityPseudoHeader = HTTPHeaderName<String>(":authority")
    /// The HTTP/2 `:scheme` pseudo header field
    static let schemePseudoHeader = HTTPHeaderName<String>(":scheme")
}


extension HTTPMethod: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        self.init(rawValue: value)
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        self.rawValue
    }
}


extension HTTPResponseStatus: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        if let intValue = Int(value) {
            self.init(statusCode: intValue)
        } else {
            return nil
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        String(code)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(reasonPhrase)
    }
}


public enum HTTPConnectionHeaderValue: HTTPHeaderFieldValueCodable {
    case close
    case keepAlive
    case upgrade
    case other(String)
    
    public init?(httpHeaderFieldValue value: String) {
        switch value.lowercased() {
        case "close":
            self = .close
        case "keep-alive":
            self = .keepAlive
        case "upgrade":
            self = .upgrade
        default:
            self = .other(value)
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .close:
            return "close"
        case .keepAlive:
            return "Keep-Alive"
        case .upgrade:
            return "Upgrade"
        case .other(let value):
            return value
        }
    }
}


public enum HTTPUpgradeHeaderValue: HTTPHeaderFieldValueCodable {
    case http2
    case webSocket
    case other(String)
    
    public init?(httpHeaderFieldValue value: String) {
        switch value {
        case "HTTP/2.0", "HTTP/2":
            self = .http2
        case "websocket":
            self = .webSocket
        default:
            self = .other(value)
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .http2:
            return "HTTP/2.0"
        case .webSocket:
            return "websocket"
        case .other(let value):
            return value
        }
    }
}


public enum TransferCodingHTTPHeaderValue: String, HTTPHeaderFieldValueCodable {
    case chunked = "chunked"
    case compress = "compress"
    case deflate = "deflate"
    case gzip = "gzip"
    
    public init?(httpHeaderFieldValue value: String) {
        self.init(rawValue: value)
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        self.rawValue
    }
}


public enum ContentEncodingHTTPHeaderValue: String, HTTPHeaderFieldValueCodable {
    case gzip = "gzip"
    case compress = "compress"
    case deflate = "deflate"
    case br = "br" // swiftlint:disable:this identifier_name
    
    public init?(httpHeaderFieldValue value: String) {
        self.init(rawValue: value)
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        self.rawValue
    }
}


public struct SetCookieHTTPHeaderValue: HTTPHeaderFieldValueCodable {
    public enum SameSite: String {
        case strict = "Strict"
        case lax = "Lax"
        case none = "None"
    }
    
    public let cookieName: String
    public let cookieValue: String
    
    public let expires: Date?
    public let maxAge: Int?
    public let domain: String?
    public let path: String?
    public let secure: Bool? // swiftlint:disable:this discouraged_optional_boolean
    public let httpOnly: Bool? // swiftlint:disable:this discouraged_optional_boolean
    public let sameSite: SameSite?
    
    /// Create a new `SetCookieHeaderValue` object from the specified values.
    /// - Note: This will, in conformance with the respective standard, automatically set the `secure` field to `true` if `sameSite` is set to `SameSite.none`, regardless of the `secure` fields' actual value.
    public init(
        cookieName: String,
        cookieValue: String,
        expires: Date?,
        maxAge: Int?,
        domain: String?,
        path: String?,
        secure: Bool?, // swiftlint:disable:this discouraged_optional_boolean
        httpOnly: Bool?, // swiftlint:disable:this discouraged_optional_boolean
        sameSite: SameSite?
    ) {
        self.cookieName = cookieName
        self.cookieValue = cookieValue
        self.expires = expires
        self.maxAge = maxAge
        self.domain = domain
        self.path = path
        self.secure = sameSite == SameSite.none ? true : secure
        self.httpOnly = httpOnly
        self.sameSite = sameSite
    }
    
    
    public init?(httpHeaderFieldValue value: String) {
        fatalError("Not yet implemented")
    }
    
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        var retval = "\(cookieName)=\(cookieValue)"
        if let expires = expires {
            retval.append("; Expires=\(expires.encodeToHTTPHeaderFieldValue())")
        }
        if let maxAge = maxAge {
            retval.append("; MaxAge=\(maxAge.encodeToHTTPHeaderFieldValue())")
        }
        if let domain = domain {
            retval.append("; Domain=\(domain.encodeToHTTPHeaderFieldValue())")
        }
        if let path = path {
            retval.append("; Path=\(path.encodeToHTTPHeaderFieldValue())")
        }
        if let secure = secure, secure {
            retval.append("; Secure")
        }
        if let httpOnly = httpOnly, httpOnly {
            retval.append("; HttpOnly")
        }
        if let sameSite = sameSite {
            retval.append("; SameSite=\(sameSite.rawValue)")
        }
        return retval
    }
}


public enum AuthorizationHTTPHeaderValue: HTTPHeaderFieldValueCodable {
    case basic(credentials: String)
    /// See [RFC6750](https://datatracker.ietf.org/doc/html/rfc6750)
    case bearer(token: String)
    case other(type: String, credentials: String)
    
    
    public init?(httpHeaderFieldValue value: String) {
        guard let typeEndIdx = value.firstIndex(of: " ") else {
            return nil
        }
        let type = String(value[..<typeEndIdx])
        let rawCredentials = String(value[typeEndIdx...].dropFirst())
        switch type.lowercased() {
        case "basic":
            self = .basic(credentials: rawCredentials)
        case "bearer":
            self = .bearer(token: rawCredentials)
        default:
            self = .other(type: type, credentials: rawCredentials)
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .basic(let credentials):
            return "Basic \(credentials)"
        case .bearer(let token):
            return "Bearer \(token)"
        case let .other(type, credentials):
            return "\(type) \(credentials)"
        }
    }
}


public enum ETagHTTPHeaderValue: HTTPHeaderFieldValueCodable {
    case weak(String)
    case strong(String)
    
    public init?(httpHeaderFieldValue value: String) {
        if value.hasPrefix("W/") {
            self = .weak(value)
        } else {
            self = .strong(value)
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .weak(let value), .strong(let value):
            return value
        }
    }
}


// MARK: Extensions for raw types that may appear as HTTP header field values


extension String: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        self = value
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        self
    }
}


extension Int: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        self.init(value)
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        String(self)
    }
}


extension Date: HTTPHeaderFieldValueCodable {
    private static let httpDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "GMT")!
        fmt.dateFormat = "EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"
        return fmt
    }()
    
    public init?(httpHeaderFieldValue value: String) {
        if let date = Self.httpDateFormatter.date(from: value) {
            self = date
        } else {
            return nil
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        Self.httpDateFormatter.string(from: self)
    }
}


extension Array: HTTPHeaderFieldValueCodable where Element: HTTPHeaderFieldValueCodable {
    public init?(httpHeaderFieldValue value: String) {
        self.init()
        for component in value.split(separator: ",") {
            guard let headerValue = Element(httpHeaderFieldValue: String(component.trimmingLeadingWhitespace())) else {
                return nil
            }
            self.append(headerValue)
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        self.map { $0.encodeToHTTPHeaderFieldValue() }
            .joined(separator: ", ")
    }
}

public enum AccessControlAllowOriginHeaderValue: HTTPHeaderFieldValueCodable {
    case wildcard
    case origin(String)
    case null
    
    public init?(httpHeaderFieldValue value: String) {
        switch value {
        case "*":
            self = .wildcard
        case "null":
            self = .null
        default:
            self = .origin(value)
        }
    }
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        switch self {
        case .wildcard:
            return "*"
        case .origin(let origin):
            return origin
        case .null:
            return "null"
        }
    }
}
