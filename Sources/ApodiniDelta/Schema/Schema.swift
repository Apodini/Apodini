//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

class SchemaName: PrimitiveValueWrapper<String> {}
class IsEnum: PrimitiveValueWrapper<Bool> {}

/// Schema of a specific type
struct Schema {
    /// The name of the type
    let typeName: SchemaName

    /// Properties of the schema
    let properties: Set<SchemaProperty>

    /// Indicates whether the schema is an enumeration
    /// If that is the case, the properties represent the cases as strings
    let isEnumeration: IsEnum

    /// The reference to the own schema
    var reference: SchemaReference {
        .reference(typeName.value)
    }

    private init(typeName: String, properties: Set<SchemaProperty>, isEnumeration: Bool = false) {
        self.typeName = .init(typeName)
        self.properties = properties
        self.isEnumeration = .init(isEnumeration)
    }

    func updated(typeName: String) -> Schema {
        .init(typeName: typeName, properties: properties, isEnumeration: isEnumeration.value)
    }
}

// MARK: - Convenience
extension Schema {
    static func primitive(type: PrimitiveType) -> Schema {
        .init(typeName: type.description, properties: .empty)
    }

    static func complex(typeName: String, properties: Set<SchemaProperty>) -> Schema {
        .init(typeName: typeName, properties: properties)
    }

    static func enumeration(typeName: String, cases: String...) -> Schema {
        .init(typeName: typeName, properties: Set(cases.enumerated().map { .enumCase(named: $1, offset: $0 + 1) }), isEnumeration: true)
    }

    static func enumeration(typeName: String, cases: [String]) -> Schema {
        .init(typeName: typeName, properties: Set(cases.enumerated().map { .enumCase(named: $1, offset: $0 + 1) }), isEnumeration: true)
    }
}

// MARK: - Codable
extension Schema: Codable {
    // MARK: Private Inner Types
    private enum CodingKeys: String, CodingKey {
        case typeName, properties, isEnumeration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        typeName = try container.decode(SchemaName.self, forKey: .typeName)
        properties = try container.decodeIfPresent(Set<SchemaProperty>.self, forKey: .properties) ?? .empty
        isEnumeration = try container.decodeIfPresent(IsEnum.self, forKey: .isEnumeration) ?? .init(false)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(typeName, forKey: .typeName)

        if !properties.isEmpty { try container.encode(properties, forKey: .properties) }
        if isEnumeration.value { try container.encode(isEnumeration, forKey: .isEnumeration) }
    }
}

// MARK: - Hashable
extension Schema: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(typeName)
        hasher.combine(properties)
        hasher.combine(isEnumeration)
    }
}

// MARK: - Equatable
extension Schema: Equatable {
    static func == (lhs: Schema, rhs: Schema) -> Bool {
        lhs.typeName == rhs.typeName
            && lhs.properties == rhs.properties
            && lhs.isEnumeration == rhs.isEnumeration
    }
}

// MARK: - ComparableObject
extension Schema: ComparableObject {
    var deltaIdentifier: DeltaIdentifier { .init(typeName.value) }

    func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
        let context: ChangeContextNode
        if !embeddedInCollection {
            guard let ownContext = result.change(for: Self.self) else {
                return nil
            }
            context = ownContext
        } else {
            context = result
        }

        let changes = [
            typeName.change(in: context),
            properties.evaluate(node: context),
            isEnumeration.change(in: context)
        ].compactMap { $0 }

        guard !changes.isEmpty else {
            return nil
        }

        return .compositeChange(location: Self.changeLocation, changes: changes)
    }

    func compare(to other: Schema) -> ChangeContextNode {
        let context = ChangeContextNode()

        context.register(compare(\.typeName, with: other), for: SchemaName.self)
        context.register(result: compare(\.properties, with: other), for: SchemaProperty.self)
        context.register(compare(\.isEnumeration, with: other), for: IsEnum.self)

        return context
    }
}
