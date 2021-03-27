//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

class ValueChange: Change {

    struct ChangedValue: Codable, Equatable { // TODO make values generic
        var from: String
        var to: String
    }

    private enum CodingKeys: String, CodingKey {
        case changedValue
    }

    let changedValue: ChangedValue

    init(location: String, from: String, to: String) {
        self.changedValue = ChangedValue(from: from, to: to)

        super.init(location: location)
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
