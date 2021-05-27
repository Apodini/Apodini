//
//  MimeType.swift
//  
//
//  Created by Paul Schmiedmayer on 5/26/21.
//

#warning("@Jan: Missing some more mime types here")
public enum MimeType: Encodable {
    enum CodingKeys: CodingKey {
        case type
        case subtype
        case parameters
    }
    
    public enum TextSubtype: String, Encodable {
        case csv
        case html
        case plain
        case css
        case javascript
        case xml
        case php
    }
    
    public enum ApplicationSubtype: String, Encodable {
        case pdf
        case zip
        case json
        case octetstream = "octet-stream"
        case graphql
        case sql
        case xml
    }
    
    public enum ImageSubtype: String, Encodable {
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
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(subtype, forKey: .subtype)
        try container.encode(parameters, forKey: .parameters)
    }
}
