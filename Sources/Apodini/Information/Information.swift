//
//  Information.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

import Foundation


/// Information describes additional metadata that can be attached to a `Response` or can be found in the `ConnectionContext` in the `@Environment` of a `Handler`.
public enum Information {
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd LLL yyyy HH:mm:ss zzz"
        return dateFormatter
    }()
    
    /// An `Information` instance carrying `Authorization` information
    case authorization(Authorization)
    /// An `Information` instance carrying information about cookies
    case cookies([String: String])
    /// An `Information` instance carrying information that redirects a client to a new location
    case redirectTo(URL)
    /// An `Information` instance carrying information that indicates when a resource expires for caching information
    case expires(Date)
    /// An `Information` instance carrying an eTag that identifies a resource to enable caching
    case eTag(String, weak: Bool = false)
    /// A custom `Information` instance  that can be used to encode custom information
    case custom(key: String, value: String)
    
    
    /// Creates an key value par of the `Information` instance.
    public var keyValuePair: (key: InformationKey, value: String) {
        switch self {
        case let .authorization(authorization):
            return (key, authorization.value)
        case let .cookies(cookies):
            return (key, cookies.map { "\($0.0)=\($0.1)" }.joined(separator: "; "))
        case let .redirectTo(url):
            return (key, url.absoluteString)
        case let .expires(date):
            return (key, Information.dateFormatter.string(from: date))
        case let .eTag(value, isWeak):
            return (key, "\(isWeak ? "W/" : "")\"\(value)\"")
        case let .custom(_, value):
            return (self.key, value)
        }
    }
    
    var key: InformationKey {
        switch self {
        case .authorization:
            return .authorization
        case .cookies:
            return .cookies
        case .redirectTo:
            return .redirectTo
        case .expires:
            return .expires
        case .eTag:
            return .eTag
        case let .custom(key, _):
            return .unknown(key)
        }
    }
    
    /// Creeate an `Information` based on a key and value
    /// Tries to match it to the implemented `Information` types. If there is no clear match the function returns a `.custom` `Information` instance.
    /// - Parameters:
    ///   - key: The `Information` key
    ///   - value: The `Information` value
    public init(key: String, value: String) {
        let parsedInformation: Information?
        
        switch key {
        case "Authorization":
            parsedInformation = Information.parseAuthorization(value)
        case "Cookie":
            parsedInformation = Information.parseCookie(value)
        case "Location":
            parsedInformation = Information.parseLocation(value)
        case "Expires":
            parsedInformation = Information.parseExpires(value)
        case "ETag":
            parsedInformation = Information.parseETag(value)
        default:
            parsedInformation = .custom(key: key, value: value)
        }
        
        self = parsedInformation ?? .custom(key: key, value: value)
    }
    
    private static func parseAuthorization(_ value: String) -> Information? {
        guard let authorization = Authorization(value) else {
            return nil
        }
        
        return .authorization(authorization)
    }
    
    private static func parseCookie(_ value: String) -> Information? {
        let keyValuePairs = value.components(separatedBy: "; ")
        var cookies: [String: String] = Dictionary(minimumCapacity: keyValuePairs.count)
        
        for keyValuePair in keyValuePairs {
            let substrings = keyValuePair.split(separator: "=", maxSplits: 1)
            guard substrings.count == 2 else {
                return nil
            }
            cookies[String(substrings[0])] = String(substrings[1])
        }
        
        return .cookies(cookies)
    }
    
    private static func parseLocation(_ value: String) -> Information? {
        guard let url = URL(string: value) else {
            return nil
        }
        
        return .redirectTo(url)
    }
    
    private static func parseExpires(_ value: String) -> Information? {
        guard let date = Information.dateFormatter.date(from: value) else {
            return nil
        }
        return .expires(date)
    }
    
    private static func parseETag(_ value: String) -> Information? {
        let isWeak = value.hasPrefix("W/")
        var eTagValue = value
        if isWeak {
            eTagValue.removeFirst(2)
        }
        
        guard eTagValue.hasPrefix("\"") && eTagValue.hasSuffix("\"") else {
            return nil
        }
        
        eTagValue.removeFirst()
        eTagValue.removeLast()
        
        return .eTag(eTagValue, weak: isWeak)
    }
}


extension Information: Hashable {
    public static func == (lhs: Information, rhs: Information) -> Bool {
        lhs.key == rhs.key
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}
