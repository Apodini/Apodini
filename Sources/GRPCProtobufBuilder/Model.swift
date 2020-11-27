//
//  File.swift
//  
//
//  Created by Nityananda on 24.11.20.
//

import Runtime

// MARK: - GRPCMessage etc.

struct GRPCMessage: Equatable, Hashable {
    struct Property: Equatable, Hashable {
        let name: String
        let isRequired: Bool = true
        let typeName: String
        let uniqueNumber: Int
    }
    
    let name: String
    let properties: Set<Property>
}

extension GRPCMessage.Property: Comparable {
    static func < (lhs: GRPCMessage.Property, rhs: GRPCMessage.Property) -> Bool {
        lhs.uniqueNumber < rhs.uniqueNumber
    }
}

// MARK: - GRPCService etc.

struct GRPCService: Equatable, Hashable {
    struct Method: Equatable, Hashable {
        let name: String
        let input: GRPCMessage
        let ouput: GRPCMessage
    }
    
    let name: String
    let methods: Set<Method>
}
