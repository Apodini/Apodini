//
//  File.swift
//  
//
//  Created by Nityananda on 12.12.20.
//

extension Message.Property {
    init(_ info: EnrichedInfo) throws {
        let particularType = ParticularType(info.typeInfo.type)
        let isRepeated = particularType.isArray
        let name = info.propertyInfo?.name ?? ""
        let suffix = particularType.isPrimitive ? "" : "Message"
        let typeName = try info.typeInfo.compatibleName() + suffix
        let uniqueNumber = info.propertiesOffset ?? 0
        
        self.init(
            isRepeated: isRepeated,
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
