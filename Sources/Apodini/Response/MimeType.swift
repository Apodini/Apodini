//
//  MimeType.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//


/// MIME type (Multipurpose Internet Mail Extensions) that expresses the format of a `Blob`
public enum MimeType: Codable, Equatable {
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
    
    
    var type: String {
        switch self {
        case .text:
            return "text"
        case .application:
            return "application"
        case .image:
            return "image"
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
        }
    }
    
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(
                try container.decode(TextSubtype.self, forKey: .subtype),
                parameters: try container.decodeIfPresent([String: String].self, forKey: .parameters) ?? [:]
            )
        case "application":
            self = .application(
                try container.decode(ApplicationSubtype.self, forKey: .subtype),
                parameters: try container.decodeIfPresent([String: String].self, forKey: .parameters) ?? [:]
            )
        case "image":
            self = .image(
                try container.decode(ImageSubtype.self, forKey: .subtype),
                parameters: try container.decodeIfPresent([String: String].self, forKey: .parameters) ?? [:]
            )
        default:
            var codingPath = decoder.codingPath
            codingPath.append(CodingKeys.type)
            throw DecodingError.valueNotFound(
                Status.self,
                DecodingError.Context(codingPath: codingPath, debugDescription: "Could not find a correct Mime Type, found: \(type)")
            )
        }
    }
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(subtype, forKey: .subtype)
        try container.encode(parameters, forKey: .parameters)
    }
}
