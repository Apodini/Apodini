//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

/// Represent a change where a value gets added at a certain `location`
class AddChange<V: Value>: Change {
    // MARK: - CodingKeys
    private enum CodingKeys: String, CodingKey {
        case addedValue
    }

    /// The `value` that has been added
    let addedValue: V

    init(location: String, addedValue: V) {
        self.addedValue = addedValue

        super.init(location: location, changeType: .addition)
    }

    // MARK: - Codable
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(addedValue, forKey: .addedValue)
        try super.encode(to: encoder)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        addedValue = try container.decode(V.self, forKey: .addedValue)
        try super.init(from: decoder)
    }

    // MARK: - Overrides
    override func isEqual(to other: Change) -> Bool {
        if let other = other as? AddChange {
            return super.isEqual(to: other) && addedValue == other.addedValue
        }

        return false
    }
}
