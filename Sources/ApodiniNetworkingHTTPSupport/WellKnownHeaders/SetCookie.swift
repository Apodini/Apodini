//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation
import ApodiniUtils


extension AnyHTTPHeaderName {
    /// The `Set-Cookie` HTTP header field
    public static let setCookie = HTTPHeaderName<[SetCookieHTTPHeaderValue]>("Set-Cookie")
}


public struct SetCookieHTTPHeaderValue: HTTPHeaderFieldValueCodable {
    private static let allowedCookieNameChars: Set<Character> = {
        Set.ascii
            .subtracting(.asciiControlCharacters)
            .subtracting([" ", "\t", "(", ")", "<", ">", "@", ",", ";", ":", "\\", "\"", "/", "[", "]", "?", "=", "{", "}"])
    }()
    
    private static let allowedCookieValueChars: Set<Character> = {
        Set.ascii
            .subtracting(.asciiControlCharacters)
            .subtracting(["\"", ",", ";", "\\", " ", "\t"])
    }()
    
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
    public let secure: Bool
    public let httpOnly: Bool
    public let sameSite: SameSite?
    
    /// Create a new `SetCookieHeaderValue` object from the specified values.
    /// - Note: This will, in conformance with the respective standard, automatically set the `secure` field to `true` if `sameSite` is set to `SameSite.none`, regardless of the `secure` fields' actual value.
    public init(
        cookieName: String,
        cookieValue: String,
        expires: Date? = nil,
        maxAge: Int? = nil,
        domain: String? = nil,
        path: String? = nil,
        secure: Bool = false,
        httpOnly: Bool = false,
        sameSite: SameSite? = nil
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
        let components = value.split(separator: ";")
        guard !components.isEmpty else {
            return nil
        }
        
        let name: String
        let value: String
        do {
            let fstComponentSplit = components[0].split(separator: "=")
            guard fstComponentSplit.count == 2 else {
                return nil
            }
            name = String(fstComponentSplit[0])
            guard name.containsOnly(charsFrom: Self.allowedCookieNameChars) else {
                return nil
            }
            value = String(fstComponentSplit[1])
            guard value.containsOnly(charsFrom: Self.allowedCookieValueChars) else {
                return nil
            }
        }
        
        let remainingAttributes: [String: String] = components[1...].mapIntoDict { (value: Substring) -> (String, String) in
            if let equalsSepIdx = value.firstIndex(of: "=") {
//                let split = value.split(separator: "=")
//                return (
//                    String(split[0].trimmingLeadingAndTrailingWhitespace()),
//                    String(split[1].trimmingLeadingAndTrailingWhitespace())
//                )
                return (
                    String(value[value.startIndex..<equalsSepIdx].trimmingLeadingAndTrailingWhitespace()),
                    String(value[value.index(after: equalsSepIdx)..<value.endIndex].trimmingLeadingAndTrailingWhitespace())
                )
            } else {
                // If the component does not specify a value, we simply record its presence
                return (String(value.trimmingLeadingAndTrailingWhitespace()), "")
            }
        }
        
        self.init(
            cookieName: name,
            cookieValue: value,
            expires: remainingAttributes["Expires"].flatMap { .init(httpHeaderFieldValue: $0) },
            maxAge: remainingAttributes["Max-Age"].flatMap { .init(httpHeaderFieldValue: $0) },
            domain: remainingAttributes["Domain"].flatMap { .init(httpHeaderFieldValue: $0) },
            path: remainingAttributes["Path"].flatMap { .init(httpHeaderFieldValue: $0) },
            secure: remainingAttributes.keys.contains("Secure"),
            httpOnly: remainingAttributes.keys.contains("HttpOnly"),
            sameSite: remainingAttributes["SameSite"].flatMap { SameSite(rawValue: $0) }
        )
    }
    
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        var retval = "\(cookieName)=\(cookieValue)"
        if let expires = expires {
            retval.append("; Expires=\(expires.encodeToHTTPHeaderFieldValue())")
        }
        if let maxAge = maxAge {
            retval.append("; Max-Age=\(maxAge.encodeToHTTPHeaderFieldValue())")
        }
        if let domain = domain {
            retval.append("; Domain=\(domain.encodeToHTTPHeaderFieldValue())")
        }
        if let path = path {
            retval.append("; Path=\(path.encodeToHTTPHeaderFieldValue())")
        }
        if secure {
            retval.append("; Secure")
        }
        if httpOnly {
            retval.append("; HttpOnly")
        }
        if let sameSite = sameSite {
            retval.append("; SameSite=\(sameSite.rawValue)")
        }
        return retval
    }
}
