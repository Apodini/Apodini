//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniUtils


/// A URI, i.e. a URL
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
        guard let url = URL(string: string) else {
            return nil
        }
        self.init(
            scheme: .init(rawValue: url.scheme ?? "http")!,
            hostname: url.host ?? "",
            port: url.port,
            path: url.path,
            rawQuery: url.query ?? "",
            fragment: url.fragment ?? ""
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
    
}


extension URI: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(string: value)!
    }
}


extension URL {
    /// Constructs, a `Foundation.URL` from the specified `URI`.
    public init(_ uri: URI) {
        var components = URLComponents()
        components.scheme = uri.scheme.rawValue
        components.host = uri.hostname
        components.port = uri.port
        components.path = uri.path
        components.query = uri.rawQuery.isEmpty ? nil : uri.rawQuery
        components.fragment = uri.fragment.isEmpty ? nil : uri.fragment
        self = components.url!
        //return components.url!
    }
}
