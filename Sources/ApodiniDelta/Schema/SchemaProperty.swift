//
//  File.swift
//  
//
//  Created by Eldi Cano on 20.03.21.
//

import Foundation

struct SchemaProperty {

    // MARK: - Inner type
    enum PropertyType: Equatable, Hashable {
        case optional
        case exactlyOne
        case array
        case dictionary(key: PrimitiveType)
    }

    let name: String
    let type: PropertyType
    let reference: SchemaReference

    private init(named: String, type: PropertyType, reference: SchemaReference) {
        self.name = named
        self.type = type
        self.reference = reference
    }

    static func initialize(from reflectionInfo: ReflectionInfo, in builder: inout SchemaBuilder) -> SchemaProperty? {
        guard
            let name = reflectionInfo.propertyInfo?.name,
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
        return .init(named: name, type: propertyType, reference: schemaReference)
    }
}

extension SchemaProperty {

    static func property(named: String, type: PropertyType, reference: SchemaReference) -> SchemaProperty {
        .init(named: named, type: type, reference: reference)
    }

    static func enumCase(named: String) -> SchemaProperty {
        .init(named: named, type: .exactlyOne, reference: .reference(.string))
    }
}

extension SchemaProperty: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(reference)
    }
}

extension SchemaProperty: Equatable {

    static func == (lhs: SchemaProperty, rhs: SchemaProperty) -> Bool {
        lhs.name == rhs.name
            && lhs.type == rhs.type
            && lhs.reference == rhs.reference
    }
}
