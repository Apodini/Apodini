//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniUtils


/// A URL
public struct URI: LosslessStringConvertible {
    public enum Scheme: String {
        case http
        case https
    }
    public let scheme: Scheme
    public let hostname: String
    public let port: Int?
    public let path: String
    public let rawQuery: String
    public let fragment: String
    public let queryItems: [String: String?]
    
    
    public init(
        scheme: Scheme,
        hostname: String,
        port: Int? = nil,
        path: String = "/",
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
            scheme: .init(rawValue: nsUrl.scheme ?? "http")!,
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
    
    /// User-readable string value of this URI
    public var stringValue: String { description }
    
    /// The URI's path, including the query string (if applicable) and fragment (if applicable)
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
    
    
    /// Constructs, from this `URL`, a `Foundation.URL`
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


extension URI: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(string: value)!
    }
}
