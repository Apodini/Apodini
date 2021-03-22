//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

struct Schema {
    var typeName: String
    var properties: Set<SchemaProperty>
    let isEnumeration: Bool

    var reference: SchemaReference {
        .reference(typeName)
    }

    private init(typeName: String, properties: Set<SchemaProperty>, isEnumeration: Bool = false) {
        self.typeName = typeName
        self.properties = properties
        self.isEnumeration = isEnumeration
    }

    func updated(typeName: String) -> Schema {
        .init(typeName: typeName, properties: properties, isEnumeration: isEnumeration)
    }

}

extension Schema {

    static func primitive(type: PrimitiveType) -> Schema {
        return .init(typeName: type.description, properties: .empty)
    }

    static func complex(typeName: String, properties: Set<SchemaProperty>) -> Schema {
        return .init(typeName: typeName, properties: properties)
    }

    static func enumeration(typeName: String, cases: String...) -> Schema {
        .init(typeName: typeName, properties: Set(cases.enumerated().map { .enumCase(named: $1, offset: $0 + 1) }), isEnumeration: true)
    }

    static func enumeration(typeName: String, cases: [String]) -> Schema {
        .init(typeName: typeName, properties: Set(cases.enumerated().map { .enumCase(named: $1, offset: $0 + 1) }), isEnumeration: true)
    }
}

extension Schema: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(typeName)
        hasher.combine(properties)
        hasher.combine(isEnumeration)
    }
}

extension Schema: Equatable {

    static func == (lhs: Schema, rhs: Schema) -> Bool {
        lhs.typeName == rhs.typeName
            && lhs.properties == rhs.properties
            && lhs.isEnumeration == rhs.isEnumeration
    }

}
