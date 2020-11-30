//
//  File.swift
//  
//
//  Created by Nityananda on 24.11.20.
//

import Runtime

// MARK: - GRPCMessage etc.

struct Message: Equatable, Hashable {
    struct Property: Equatable, Hashable {
        let name: String
        let isRequired: Bool = true
        let typeName: String
        let uniqueNumber: Int
    }
    
    let name: String
    let properties: Set<Property>
}

extension Message.Property: Comparable {
    static func < (lhs: Message.Property, rhs: Message.Property) -> Bool {
        lhs.uniqueNumber < rhs.uniqueNumber
    }
}

// MARK: - GRPCService etc.

struct Service: Equatable, Hashable {
    struct Method: Equatable, Hashable {
        let name: String
        let input: Message
        let ouput: Message
    }
    
    let name: String
    let methods: Set<Method>
}
