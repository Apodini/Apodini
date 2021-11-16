//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniUtils

// swiftlint:disable redundant_string_enum_value
// ^^ We do in fact want the redundancy here, since this will prevent the media types from breaking
// in case someone in the future decides to rename the enum cases, w/out realising that Apodini was
// relying on e.g. the specific spelling or whether or not they were capitalised (same also applies
// to the well-known HTTP header values).


/// A HTTP Media Type, as defined in [RFC6838](https://datatracker.ietf.org/doc/html/rfc6838)
public struct HTTPMediaType: HTTPHeaderFieldValueCodable, Equatable, Hashable {
    public let type: String
    public let subtype: String
    public let parameters: [String: String]
    
    
    public init(type: String, subtype: String, parameters: [String: String] = [:]) {
        precondition(!type.isEmpty && !subtype.isEmpty, "Invalid input")
        self.type = type
        self.subtype = subtype
        self.parameters = parameters
    }
    
    public init?(string: String) {
        guard let typeSubtypeSeparatorIdx = string.firstIndex(of: "/") else {
            return nil
        }
        self.type = String(string[..<typeSubtypeSeparatorIdx])
        guard let firstParamIdx = string.firstIndex(of: ";", after: typeSubtypeSeparatorIdx) else {
            // No parameters, meaning that the entire rest of the string is the subtype
            self.subtype = String(string.suffix(from: typeSubtypeSeparatorIdx).dropFirst())
            self.parameters = [:]
            return
        }
        self.subtype = String(string[typeSubtypeSeparatorIdx..<firstParamIdx].dropFirst())
        var parameters: [String: String] = [:]
        let rawParameters = string[firstParamIdx...].split(separator: ";").map { $0.trimmingLeadingAndTrailingWhitespace() }
        for component in rawParameters {
            let componentComponents = component.components(separatedBy: "=")
            guard componentComponents.count == 2 else {
                // We're expecting two components were produced from splitting the component into its components.
                return nil
            }
            parameters[componentComponents[0]] = componentComponents[1]
        }
        self.parameters = parameters
    }
    
    
    public init?(httpHeaderFieldValue: String) {
        self.init(string: httpHeaderFieldValue)
    }
    
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        var retval = "\(type)/\(subtype)"
        for (key, value) in parameters {
            retval.append("; \(key)=\(value)")
        }
        return retval
    }
    
    
    /// The suffix of the subtype
    public var suffix: String? {
        if let idx = subtype.firstIndex(of: "+") {
            return String(subtype[idx...])
        } else {
            return nil
        }
    }
    
    
    /// The media type's subtype, with the suffix removed if applicable
    public var subtypeWithoutSuffix: String {
        if let idx = subtype.firstIndex(of: "+") {
            return String(subtype[..<idx])
        } else {
            return subtype
        }
    }
    
    
    /// Whether the two media types are equal when ignoring their suffixes and parameters
    public func equalsIgnoringSuffixAndParameters(_ other: HTTPMediaType) -> Bool {
        self.type == other.type && self.subtypeWithoutSuffix == other.subtypeWithoutSuffix
    }
}


extension HTTPMediaType {
    /// The `text/plain` media type, with a `charset=utf-8` parameter.
    public static let text = HTTPMediaType(type: "text", subtype: "plain", parameters: ["charset": "utf-8"])
    /// The `text/html` media type, with a `charset=utf-8` parameter.
    public static let html = HTTPMediaType(type: "text", subtype: "html", parameters: ["charset": "utf-8"])
    /// The `application/json` media type, with a `charset=utf-8` parameter.
    public static let json = HTTPMediaType(type: "application", subtype: "json", parameters: ["charset": "utf-8"])
    /// The `application/xml` media type, with a `charset=utf-8` parameter.
    public static let xml = HTTPMediaType(type: "application", subtype: "xml", parameters: ["charset": "utf-8"])
    /// The `application/pdf` media type.
    public static let pdf = HTTPMediaType(type: "application", subtype: "pdf")
    /// The `application/grpc` media type, without an explicitly specified encoding.
    public static let gRPC = HTTPMediaType(type: "application", subtype: "grpc")
    
    
    /// MediaType charset options
    public enum CharsetParameterValue: String {
        case utf8 = "utf-8"
    }
    
    private static func makeMediaType(withType type: String, subtype: String, charset: CharsetParameterValue?) -> HTTPMediaType {
        HTTPMediaType(type: type, subtype: subtype, parameters: charset.map { ["charset": $0.rawValue] } ?? [:])
    }
    
    /// Creates an `application/json` media type with the specified charset as its parameter
    public static func json(charset: CharsetParameterValue? = .utf8) -> HTTPMediaType {
        makeMediaType(withType: "application", subtype: "json", charset: charset)
    }
    
    
    /// gRPC media type subtype suffix options
    public enum GRPCEncodingOption: String {
        case proto = "proto"
        case json = "json"
    }
    
    /// Creates a gRPC media type with the specified encoding appended as the subtype's suffix
    public static func gRPC(_ encoding: GRPCEncodingOption) -> HTTPMediaType {
        HTTPMediaType(type: "application", subtype: "grpc+\(encoding.rawValue)")
    }
}
