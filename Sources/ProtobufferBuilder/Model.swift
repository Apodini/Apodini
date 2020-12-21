//
//  File.swift
//  
//
//  Created by Nityananda on 24.11.20.
//

// MARK: - Message and Message.Property

struct Message: Equatable, Hashable {
    struct Property: Equatable, Hashable {
        enum FieldRule: String {
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

// MARK: - Service and Service.Method

struct Service: Equatable, Hashable {
    struct Method: Equatable, Hashable {
        let name: String
        let input: Message
        let ouput: Message
    }
    
    let name: String
    let methods: Set<Method>
}
