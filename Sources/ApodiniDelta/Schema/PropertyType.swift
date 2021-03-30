//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation

extension PropertyType: ComparableProperty {}

enum PropertyType: Equatable, Hashable {
    case optional
    case exactlyOne
    case array
    case dictionary(key: PrimitiveType)
}

extension PropertyType: Codable {
    private enum CodingKeys: String, CodingKey {
        case optional, exactlyOne, array, dictionary
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .optional:
            try container.encode(true, forKey: .optional)
        case .exactlyOne:
            try container.encode(true, forKey: .exactlyOne)
        case .array:
            try container.encode(true, forKey: .array)
        case .dictionary(key: let key):
            try container.encode(key, forKey: .dictionary)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first
        switch key {
        case .optional: self = .optional
        case .exactlyOne: self = .exactlyOne
        case .array: self = .array
        case .dictionary: self = .dictionary(key: try container.decode(PrimitiveType.self, forKey: .dictionary))
        default: fatalError("Unabled to decode enum PropertyType")
        }
    }
}
