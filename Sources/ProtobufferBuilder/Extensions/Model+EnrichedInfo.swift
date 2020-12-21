//
//  File.swift
//  
//
//  Created by Nityananda on 12.12.20.
//

extension Message.Property {
    init(_ info: EnrichedInfo) throws {
        let particularType = ParticularType(info.typeInfo.type)
        let name = info.propertyInfo?.name ?? ""
        let suffix = particularType.isPrimitive ? "" : "Message"
        let typeName = try info.typeInfo.compatibleName() + suffix
        let uniqueNumber = info.propertiesOffset ?? 0
        
        let fieldRule: FieldRule
        switch info.cardinality {
        case .zeroToOne:
            fieldRule = .optional
        case .exactlyOne:
            fieldRule = .required
        case .zeroToMany:
            fieldRule = .repeated
        }
        
        self.init(
            fieldRule: fieldRule,
            name: name,
            typeName: typeName,
            uniqueNumber: uniqueNumber
        )
    }
}

extension Message {
    init(_ node: Node<Property>) {
        let name = node.value.typeName
        let properties = node.children.map(\.value)
        
        self.init(
            name: name,
            properties: Set(properties)
        )
    }
}
