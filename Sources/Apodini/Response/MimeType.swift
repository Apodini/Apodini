//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

/// MIME type (Multipurpose Internet Mail Extensions) that expresses the format of a `Blob`
public enum MimeType: Codable, Equatable, CustomStringConvertible {
    enum CodingKeys: CodingKey {
        case type
        case subtype
        case parameters
    }
    
    /// Text-only data (https://www.iana.org/assignments/media-types/media-types.xhtml#text)
    public enum TextSubtype: String, Codable, Hashable {
        case csv
        case html
        case plain
        case css
        case javascript
        case xml
        case php
    }
    
    /// Any kind of binary data (https://www.iana.org/assignments/media-types/media-types.xhtml#application)
    public enum ApplicationSubtype: String, Codable, Hashable {
        case pdf
        case zip
        case json
        case octetstream = "octet-stream"
        case graphql
        case sql
        case xml
    }
    
    /// Any kind of image data (https://www.iana.org/assignments/media-types/media-types.xhtml#image)
    public enum ImageSubtype: String, Codable, Hashable {
        case png
        case jpeg
        case gif
        case svg = "svg+html"
    }
    
    case text(TextSubtype, parameters: [String: String] = [:])
    case application(ApplicationSubtype, parameters: [String: String] = [:])
    case image(ImageSubtype, parameters: [String: String] = [:])
    case custom(type: String, subtype: String, parameters: [String: String] = [:])
    
    
    var type: String {
        switch self {
        case .text:
            return "text"
        case .application:
            return "application"
        case .image:
            return "image"
        case let .custom(type, _, _):
            return type
        }
    }
    
    var subtype: String {
        switch self {
        case let .text(subtype, _):
            return subtype.rawValue
        case let .application(subtype, _):
            return subtype.rawValue
        case let .image(subtype, _):
            return subtype.rawValue
        case let .custom(_, subtype, _):
            return subtype
        }
    }
    
    var parameters: [String: String] {
        switch self {
        case let .text(_, parameters):
            return parameters
        case let .application(_, parameters):
            return parameters
        case let .image(_, parameters):
            return parameters
        case let .custom(_, _, parameters):
            return parameters
        }
    }
    
    public var description: String {
        "\(type)/\(subtype)\(parameters.isEmpty ? "" : ";")\(parameters.map { "\($0.0)=\($0.1)" }.joined(separator: ";"))"
    }
    
    
    public init?(_ description: String) {
        let splits = description.split(separator: ";")
        guard let typeAndSubtype = splits.first?.split(separator: "/"),
              typeAndSubtype.count == 2,
              let type = typeAndSubtype.first,
              let subType = typeAndSubtype.last
        else {
            return nil
        }
        let parametersArray: [(String, String)] = splits
            .dropFirst()
            .compactMap { substring in
                let parameterSpiit = substring.split(separator: "=")
                guard parameterSpiit.count == 2, let key = parameterSpiit.first, let value = parameterSpiit.last else {
                    return nil
                }
                return (String(key), String(value))
            }
        let parameters = parametersArray.reduce(into: [:]) { $0[$1.0] = $1.1 }
        
        self = MimeType(type: String(type), subtype: String(subType), parameters: parameters)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let subType = try container.decode(String.self, forKey: .subtype)
        let parameters = try container.decodeIfPresent([String: String].self, forKey: .parameters) ?? [:]
        
        self = MimeType(type: type, subtype: subType, parameters: parameters)
    }
    
    init(type: String, subtype: String, parameters: [String: String] = [:]) {
        switch type {
        case "text":
            guard let textSubtype = TextSubtype(rawValue: subtype) else {
                fallthrough
            }
            self = .text(textSubtype, parameters: parameters)
        case "application":
            guard let applicationSubtype = ApplicationSubtype(rawValue: subtype) else {
                fallthrough
            }
            self = .application(applicationSubtype, parameters: parameters)
        case "image":
            guard let imageSubtype = ImageSubtype(rawValue: subtype) else {
                fallthrough
            }
            self = .image(imageSubtype, parameters: parameters)
        default:
            self = .custom(type: type, subtype: subtype, parameters: parameters)
        }
    }
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(subtype, forKey: .subtype)
        try container.encode(parameters, forKey: .parameters)
    }
}
