import Foundation
import ApodiniUtils



// TODO this tyoe has a `.init(_: String)` ctor? (i.e. non-failible string init). Where is that coming from? can we get rid of it? Might be relayed to the string literal init, since it showed up around the same time...

/// A URL
public struct URI: LosslessStringConvertible, ExpressibleByStringLiteral {
    public enum Scheme: String {
        case http
        case https
        // TODO does this need to be able to support the unix domain socket stuff???
    }
    // TODO add stuff like usernames/passwords? or can we ignore that bc it wouldn't be relevant for Apodini? or would it?
    public let scheme: Scheme
    public let hostname: String
    public let port: Int?
    public let path: String
    public let rawQuery: String // TODO what to use to indicate nil values here???
    public let fragment: String
    public let queryItems: [String: String?]
    
    
    public init(
        scheme: Scheme,
        hostname: String,
        port: Int? = nil,
        path: String = "", // TODO make the default "/"?
        rawQuery: String = "",
        fragment: String = ""
    ) {
        self.scheme = scheme
        self.hostname = hostname
        self.port = port
        self.path = path
        self.rawQuery = rawQuery.hasPrefix("?") ? String(rawQuery.dropFirst()) : rawQuery
        self.fragment = fragment
        self.queryItems = .init(
            uniqueKeysWithValues: (URLComponents(string: "?\(self.rawQuery)")?.queryItems ?? []).map { ($0.name, $0.value) }
        )
    }
    
    public init?(string: String) {
        guard let nsUrl = URL(string: string) else {
            return nil
        }
        self.init(
            scheme: .init(rawValue: nsUrl.scheme ?? "http")!, // TODO can we make this assumption?
            hostname: nsUrl.host ?? "",
            port: nsUrl.port,
            path: nsUrl.path,
            rawQuery: nsUrl.query ?? "",
            fragment: nsUrl.fragment ?? ""
        )
    }
    
    
    public init?(_ description: String) {
        self.init(string: description)
    }
    
    public init(stringLiteral value: String) {
        self.init(string: value)!
    }
    
    
    public var description: String {
        var string = ""
        string.append(scheme.rawValue)
        string.append("://")
        string.append(hostname)
        if let port = port {
            string.append(":")
            string.append("\(port)")
        }
        string.append(path)
        if !rawQuery.isEmpty {
            string.append("?")
            string.append(rawQuery)
        }
        if !fragment.isEmpty {
            string.append("#")
            string.append(fragment)
        }
        return string
    }
    
    public var stringValue: String { description }
    
    public var pathIncludingQueryAndFragment: String {
        var retval: String = ""
        retval.append(path)
        if !rawQuery.isEmpty {
            retval.append("?\(rawQuery)")
        }
        if !fragment.isEmpty {
            retval.append("#\(fragment)")
        }
        return retval
    }
    
    
    public func toNSURL() -> URL {
        var components = URLComponents()
        components.scheme = scheme.rawValue
        components.host = hostname
        components.port = port
        components.path = path
        components.query = rawQuery.isEmpty ? nil : rawQuery
        components.fragment = fragment.isEmpty ? nil : fragment
        return components.url!
    }
}
