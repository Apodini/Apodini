//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

struct ChangedValue<V: Value>: Value {
    let from: V
    let to: V

    var description: String {
        "from: \(from) to: \(to)"
    }

    init(from: V, to: V) {
        self.from = from
        self.to = to
    }
}

class ValueChange<V: Value>: Change {

    private enum CodingKeys: String, CodingKey {
        case changedValue
    }

    let changedValue: ChangedValue<V>

    init(location: String, from: V, to: V) {
        changedValue = .init(from: from, to: to)

        super.init(location: location, changeType: .update)
    }

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

    override func isEqual(to other: Change) -> Bool {
        if let other = other as? ValueChange {
            return super.isEqual(to: other) && changedValue == other.changedValue
        }

        return false
    }
}
