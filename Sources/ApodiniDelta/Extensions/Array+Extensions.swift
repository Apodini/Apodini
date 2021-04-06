//
//  File.swift
//  
//
//  Created by Eldi Cano on 21.03.21.
//

import Foundation

extension Array where Element: Hashable {
    func unique() -> Set<Element> {
        Set(self)
    }
}

extension Array where Element: Equatable {
    func equalsIgnoringOrder(to other: Self) -> Bool {
        guard count == other.count else {
            return false
        }

        for change in self where !other.contains(change) {
            return false
        }

        return true
    }
}
