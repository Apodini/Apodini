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
    
    override func change<C: _Comparable>(_ type: C.Type) -> Change? {
        if let _ = super.change(C.self) {
            return self
        }
        
        for change in changes {
            if let matched = change.change(C.self) {
                return matched
            }
        }
        
        return nil
    }
    
    func flatten() -> [Change] {
        var result: [Change] = []
        
        for change in changes {
            if let change = change as? CompositeChange {
                result.append(contentsOf: change.flatten())
            } else {
                result.append(change)
            }
        }
        
        return result
    }
}
