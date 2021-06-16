//
//  Information.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

import Foundation


public enum Information {
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd LLL yyyy HH:mm:ss zzz"
        return dateFormatter
    }()
    
    case authorization(Authorization)
    case cookies([String: String])
    case redirectTo(URL)
    case expires(Date)
    case eTag(String, weak: Bool = false)
    case custom(key: String, value: String)
    
    
    public var keyValuePair: (key: String, value: String) {
        switch self {
        case let .authorization(authorization):
            return ("Authorization", authorization.value)
        case let .cookies(cookies):
            return ("Cookie", cookies.map { "\($0.0)=\($0.1)" }.joined(separator: "; "))
        case let .redirectTo(url):
            return ("Location", url.absoluteString)
        case let .expires(date):
            return ("Expires", Information.dateFormatter.string(from: date))
        case let .eTag(value, isWeak):
            return ("ETag", "\(isWeak ? "W/" : "")\"\(value)\"")
        case let .custom(key, value):
            return (key, value)
        }
    }
    
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
