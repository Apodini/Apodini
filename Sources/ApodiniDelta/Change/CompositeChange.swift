//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

/// Represents a composite change that contains additional changes that occured starting from a certain `location`
class CompositeChange: Change {

    // MARK: - CodingKeys
    private enum CodingKeys: String, CodingKey {
        case changes
    }

    /// Array of changes
    var changes: [Change]

    init(location: String, changes: [Change]) {
        self.changes = changes
        super.init(location: location, changeType: .composite)
    }

    // MARK: - Codable
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if !changes.isEmpty { try container.encode(changes, forKey: .changes) }
        try super.encode(to: encoder)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        changes = try container.decodeIfPresent([Change].self, forKey: .changes) ?? []
        try super.init(from: decoder)
    }

    // MARK: - Overrides
    override func isEqual(to other: Change) -> Bool {
        if let other = other as? CompositeChange {
            return super.isEqual(to: other) && changes.equalsIgnoringOrder(to: other.changes)
        }

        return false
    }
}

// MARK: - Array extension
extension Array where Element: Change {

    func equalsIgnoringOrder(to other: Self) -> Bool {
        guard count == other.count else { return false }

        for change in self where other.filter({ $0.isEqual(to: change) }).isEmpty {
            return false
        }

        return true
    }
}
