//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

class Change: Codable {
    var location: String

    init(location: String) {
        self.location = location
    }

    func isEqual(to other: Change) -> Bool {
        type(of: self) == type(of: other) && location == other.location
    }
}

extension Change: Equatable {
    static func == (lhs: Change, rhs: Change) -> Bool {
        lhs.isEqual(to: rhs)
    }
}

extension Array where Element: Change {

    func equalsIgnoringOrder(to other: Self) -> Bool {
        guard count == other.count else { return false }

        for change in self where other.filter({ $0.isEqual(to: change) }).isEmpty {
            return false
        }

        return true
    }
}
