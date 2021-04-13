//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

class IsEnum: PropertyValueWrapper<Bool> {}

/// Schema of a specific type
struct Schema {
    /// The name of the type
    let schemaName: SchemaName
    
    /// Properties of the schema
    let properties: Set<SchemaProperty>

    /// Indicates whether the schema is an enumeration
    /// If that is the case, the properties represent the cases as strings
    let isEnumeration: IsEnum

    private init(schemaName: SchemaName, properties: Set<SchemaProperty>, isEnumeration: Bool = false) {
        self.schemaName = schemaName
        self.properties = properties
        self.isEnumeration = .init(isEnumeration)
    }
}

// MARK: - Convenience
extension Schema {
    static func primitive(type: PrimitiveType) -> Schema {
        .init(schemaName: type.schemaName, properties: .empty)
    }

    static func complex(schemaName: SchemaName, properties: Set<SchemaProperty>) -> Schema {
        .init(schemaName: schemaName, properties: properties)
    }

    static func enumeration(schemaName: SchemaName, cases: String...) -> Schema {
        .init(schemaName: schemaName, properties: Set(cases.enumerated().map { .enumCase(named: $1, offset: $0 + 1) }), isEnumeration: true)
    }

    static func enumeration(schemaName: SchemaName, cases: [String]) -> Schema {
        .init(schemaName: schemaName, properties: Set(cases.enumerated().map { .enumCase(named: $1, offset: $0 + 1) }), isEnumeration: true)
    }
}

// MARK: - Codable
extension Schema: Codable {
    // MARK: Private Inner Types
    private enum CodingKeys: String, CodingKey {
        case schemaName, properties, isEnumeration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        schemaName = try container.decode(SchemaName.self, forKey: .schemaName)
        properties = try container.decodeIfPresent(Set<SchemaProperty>.self, forKey: .properties) ?? .empty
        isEnumeration = try container.decodeIfPresent(IsEnum.self, forKey: .isEnumeration) ?? .init(false)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(schemaName, forKey: .schemaName)

        if !properties.isEmpty { try container.encode(properties, forKey: .properties) }
        if isEnumeration.value { try container.encode(isEnumeration, forKey: .isEnumeration) }
    }
}

// MARK: - Hashable
extension Schema: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(schemaName)
        hasher.combine(properties)
        hasher.combine(isEnumeration)
    }
}

// MARK: - Equatable
extension Schema: Equatable {
    static func == (lhs: Schema, rhs: Schema) -> Bool {
        lhs.schemaName == rhs.schemaName
            && lhs.properties == rhs.properties
            && lhs.isEnumeration == rhs.isEnumeration
    }
}

// MARK: - ComparableObject
extension Schema: ComparableObject {
    var deltaIdentifier: DeltaIdentifier { schemaName.deltaIdentifier }

    func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
        guard let context = context(from: result, embeddedInCollection: embeddedInCollection) else {
            return nil
        }
        
        let changes = [
            schemaName.change(in: context),
            properties.evaluate(node: context),
            isEnumeration.change(in: context)
        ].compactMap { $0 }

        guard !changes.isEmpty else {
            return nil
        }

        return .compositeChange(location: Self.changeLocation, changes: changes)
    }

    func compare(to other: Schema) -> ChangeContextNode {
        ChangeContextNode()
            .register(compare(\.schemaName, with: other), for: SchemaName.self)
            .register(result: compare(\.properties, with: other), for: SchemaProperty.self)
            .register(compare(\.isEnumeration, with: other), for: IsEnum.self)
    }
}
