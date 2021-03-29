//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

class PropertyName: PrimitiveValueWrapper<String> {}
class PropertyOffset: PrimitiveValueWrapper<Int> {}

/// A property of a schema
struct SchemaProperty: Codable {

    /// Property name
    let name: PropertyName

    /// Offset of the property
    let offset: PropertyOffset

    /// Property type
    let type: PropertyType

    /// The reference to the schema of property type
    let reference: SchemaReference

    private init(name: String, offset: Int, type: PropertyType, reference: SchemaReference) {
        self.name = .init(name)
        self.offset = .init(offset)
        self.type = type
        self.reference = reference
    }

    static func initialize(from reflectionInfo: ReflectionInfo, in builder: inout SchemaBuilder) -> SchemaProperty? {
        guard
            let name = reflectionInfo.propertyInfo?.name,
            let offset = reflectionInfo.propertyInfo?.offset,
            let schemaReference = builder.build(for: reflectionInfo.typeInfo.type, root: false)
        else { return nil }

        let propertyType: PropertyType

        switch reflectionInfo.cardinality {
        case .zeroToOne:
            propertyType = .optional
        case .exactlyOne:
            propertyType = .exactlyOne
        case .zeroToMany(let collectionContext):
            switch collectionContext {
            case .array:
                propertyType = .array
            case .dictionary(key: let key, _):
                let primitiveType: PrimitiveType = .init(key.typeInfo.type)
                propertyType = .dictionary(key: primitiveType)
                builder.addSchema(.primitive(type: primitiveType))
            }

        }
        return .init(name: name, offset: offset, type: propertyType, reference: schemaReference)
    }
}

// MARK: - Convenience
extension SchemaProperty {

    static func property(named: String, offset: Int, type: PropertyType, reference: SchemaReference) -> SchemaProperty {
        .init(name: named, offset: offset, type: type, reference: reference)
    }

    static func enumCase(named: String, offset: Int) -> SchemaProperty {
        .init(name: named, offset: offset, type: .exactlyOne, reference: .reference(.string))
    }
}

// MARK: - Hashable
extension SchemaProperty: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(offset)
        hasher.combine(type)
        hasher.combine(reference)
    }
}

// MARK: - Equatable
extension SchemaProperty: Equatable {

    static func == (lhs: SchemaProperty, rhs: SchemaProperty) -> Bool {
        lhs.name == rhs.name
            && lhs.offset == rhs.offset
            && lhs.type == rhs.type
            && lhs.reference == rhs.reference
    }
}

// MARK: - ComparableObject
extension SchemaProperty: ComparableObject {

    var deltaIdentifier: DeltaIdentifier { .init(name.value) }

    func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
        let context: ChangeContextNode
        if !embeddedInCollection {
            guard let ownContext = result.change(for: Self.self) else { return nil }
            context = ownContext
        } else {
            context = result
        }

        let changes = [
            name.change(in: context),
            offset.change(in: context),
            type.change(in: context),
            reference.change(in: context)
        ].compactMap { $0 }

        guard !changes.isEmpty else { return nil }

        return .compositeChange(location: Self.changeLocation, changes: changes)
    }

    func compare(to other: SchemaProperty) -> ChangeContextNode {
        let context = ChangeContextNode()

        context.register(compare(\.name, with: other), for: PropertyName.self)
        context.register(compare(\.offset, with: other), for: PropertyOffset.self)
        context.register(compare(\.type, with: other), for: PropertyType.self)
        context.register(compare(\.reference, with: other), for: SchemaReference.self)

        return context
    }

}
