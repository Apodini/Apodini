//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

/// Represent a change where a value gets removed at a certain `location`
class RemoveChange<V: Value>: Change {
    // MARK: - CodingKeys
    private enum CodingKeys: String, CodingKey {
        case removedValue
    }

    /// The value that has been removed
    let removedValue: V

    init(location: String, removedValue: V) {
        self.removedValue = removedValue

        super.init(location: location, changeType: .removal)
    }

    // MARK: - Codable
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(removedValue, forKey: .removedValue)
        try super.encode(to: encoder)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        removedValue = try container.decode(V.self, forKey: .removedValue)
        try super.init(from: decoder)
    }

    // MARK: - Overrides
    override func isEqual(to other: Change) -> Bool {
        if let other = other as? RemoveChange {
            return super.isEqual(to: other) && removedValue == other.removedValue
        }

        return false
    }
}
