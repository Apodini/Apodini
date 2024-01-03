//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import ApodiniUtils
import ApodiniTypeInformation


// swiftlint:disable redundant_string_enum_value
// ^^ We do in fact want the redundancy here, since this will prevent the media types from breaking
// in case someone in the future decides to rename the enum cases, w/out realising that Apodini was
// relying on e.g. the specific spelling or whether or not they were capitalised (same also applies
// to the well-known HTTP header values).


/// A HTTP Media Type, as defined in [RFC6838](https://datatracker.ietf.org/doc/html/rfc6838)
public struct HTTPMediaType: HTTPHeaderFieldValueCodable, Equatable, Hashable, CustomStringConvertible {
    public let type: String
    public let subtype: String
    public let parameters: [String: String]
    
    
    public init(type: String, subtype: String, parameters: [String: String] = [:]) {
        precondition(!type.isEmpty && !subtype.isEmpty, "Invalid input")
        self.type = type
        self.subtype = subtype
        self.parameters = parameters
    }
    
    public init?(_ string: String) {
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
            switch componentComponents.count {
            case 2:
                parameters[componentComponents[0]] = componentComponents[1]
            case 1:
                continue
            default:
                // We're expecting two components were produced from splitting the component into its components.
                return nil
            }
        }
        self.parameters = parameters
    }
    
    
    public init?(httpHeaderFieldValue: String) {
        self.init(httpHeaderFieldValue)
    }
    
    
    public var description: String {
        encodeToHTTPHeaderFieldValue()
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


extension HTTPMediaType: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case subtype
        case parameters
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let subtype = try container.decode(String.self, forKey: .subtype)
        let parameters = try container.decode([String: String].self, forKey: .parameters)
        self = HTTPMediaType(type: type, subtype: subtype, parameters: parameters)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(subtype, forKey: .subtype)
        try container.encode(parameters, forKey: .parameters)
    }
}


extension HTTPMediaType: TypeInformationDefaultConstructor {
    /// Default type information representation
    public static func construct() -> TypeInformation {
        .object(
            name: .init(Self.self),
            properties: [
                .init(name: string(.type), type: .scalar(.string)),
                .init(name: string(.subtype), type: .scalar(.string)),
                .init(name: string(.parameters), type: .dictionary(key: .string, value: .scalar(.string)))
            ]
        )
    }

    private static func string(_ key: Self.CodingKeys) -> String {
        key.stringValue
    }
}


extension HTTPMediaType {
    /// The `text/plain` media type, with a `charset=utf-8` parameter.
    public static var text: HTTPMediaType { .text(.plain, charset: .utf8) }
    /// The `text/html` media type, with a `charset=utf-8` parameter.
    public static var html: HTTPMediaType { .text(.html, charset: .utf8) }
    /// The `application/json` media type, with a `charset=utf-8` parameter.
    public static var json: HTTPMediaType { .application(.json, charset: .utf8) }
    /// The `application/xml` media type, with a `charset=utf-8` parameter.
    public static var xml: HTTPMediaType { .application(.xml, charset: .utf8) }
    /// The `application/pdf` media type.
    public static var pdf: HTTPMediaType { .application(.pdf) }
    
    
    /// MediaType charset options
    public enum CharsetParameterValue: String {
        case utf8 = "utf-8"
    }
    
    private static func makeMediaType(
        withType type: String,
        subtype: String,
        charset: CharsetParameterValue?,
        parameters: [String: String] = [:]
    ) -> HTTPMediaType {
        var parameters = parameters
        if let charset = charset, !parameters.keys.contains("charset") {
            parameters["charset"] = charset.rawValue
        }
        return HTTPMediaType(type: type, subtype: subtype, parameters: parameters)
    }
    
    /// Creates an `application/json` media type with the specified charset as its parameter
    public static func json(charset: CharsetParameterValue? = .utf8) -> HTTPMediaType {
        makeMediaType(withType: "application", subtype: "json", charset: charset)
    }
    
    
    public enum TextSubtype: String {
        case plain = "plain"
        case html = "html"
        case xml = "xml"
    }
    
    /// Creates a `text/<subtype>` media type for the specified subtype
    public static func text(_ subtype: TextSubtype, charset: CharsetParameterValue? = .utf8, parameters: [String: String] = [:]) -> HTTPMediaType {
        makeMediaType(withType: "text", subtype: subtype.rawValue, charset: charset, parameters: parameters)
    }
    
    
    public enum ApplicationSubtype: String {
        case json = "json"
        case xml = "xml"
        case pdf = "pdf"
    }
    
    /// Creates an `application/<subtype>` media type for the specified subtype
    public static func application(
        _ subtype: ApplicationSubtype,
        charset: CharsetParameterValue? = nil,
        parameters: [String: String] = [:]
    ) -> HTTPMediaType {
        makeMediaType(withType: "application", subtype: subtype.rawValue, charset: charset, parameters: parameters)
    }
    
    
    public enum ImageSubtype: String {
        case png = "png"
        case gif = "gif"
        case jpeg = "jpeg"
    }
    
    /// Creates an `image/<subtype>` media type for the specified subtype
    public static func image(_ subtype: ImageSubtype, parameters: [String: String] = [:]) -> HTTPMediaType {
        HTTPMediaType(type: "image", subtype: subtype.rawValue, parameters: parameters)
    }
}


// ApodiniUtils extensions

extension AnyEncoder {
    /// Type-safe HTTP media type this encoder would encode into.
    public var resultMediaType: HTTPMediaType? {
        self.resultMediaTypeRawValue.flatMap { .init($0) }
    }
}
