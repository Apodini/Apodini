//
//  File.swift
//  
//
//  Created by Nityananda on 26.11.20.
//

import Runtime

extension TypeInfo: Equatable, Hashable {
    public static func == (lhs: TypeInfo, rhs: TypeInfo) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
