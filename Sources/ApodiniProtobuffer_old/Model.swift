//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//           

// MARK: - Message

struct ProtobufferMessage: Equatable, Hashable {
    struct Property: Equatable, Hashable {
        enum FieldRule {
            case optional
            case required
            case repeated
        }
        
        let fieldRule: FieldRule
        let name: String
        let typeName: String
        let uniqueNumber: Int
    }
    
    let name: String
    let properties: Set<Property>
}

// MARK: - Service

struct ProtobufferService: Equatable, Hashable {
    struct Method: Equatable, Hashable {
        let name: String
        let input: ProtobufferMessage
        let ouput: ProtobufferMessage
    }
    
    let name: String
    let methods: Set<Method>
}
