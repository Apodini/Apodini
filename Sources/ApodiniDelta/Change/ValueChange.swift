//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

/// Container for an updated value
struct ChangedValue<V: Value>: Value {
    /// Old value
    let from: V

    /// New value
    let to: V

    init(from: V, to: V) {
        self.from = from
        self.to = to
    }
}

/// Represents a change where a value gets updated at a certain `location`
class ValueChange<V: Value>: Change {
    // MARK: - CodingKeys
    private enum CodingKeys: String, CodingKey {
        case changedValue
    }

    /// Value that has been updated
    let changedValue: ChangedValue<V>

    init(location: String, from: V, to: V) {
        changedValue = .init(from: from, to: to)

        super.init(location: location, changeType: .update)
    }

    // MARK: - Codable
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(changedValue, forKey: .changedValue)
        try super.encode(to: encoder)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        changedValue = try container.decode(ChangedValue.self, forKey: .changedValue)
        try super.init(from: decoder)
    }

    // MARK: - Override
    override func isEqual(to other: Change) -> Bool {
        if let other = other as? ValueChange {
            return super.isEqual(to: other) && changedValue == other.changedValue
        }

        return false
    }
}
