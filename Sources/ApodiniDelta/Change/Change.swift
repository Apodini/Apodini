//
//  File.swift
//  
//
//  Created by Eldi Cano on 27.03.21.
//

import Foundation

class Change: Codable {
    let location: String
    let changeType: ChangeType

    init(location: String, changeType: ChangeType) {
        self.location = location
        self.changeType = changeType
    }

    func isEqual(to other: Change) -> Bool {
        type(of: self) == type(of: other)
            && location == other.location
            && changeType == other.changeType
    }
}

extension Change: Equatable {
    static func == (lhs: Change, rhs: Change) -> Bool {
        lhs.isEqual(to: rhs)
    }
}
