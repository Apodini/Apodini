//
//  File.swift
//  
//
//  Created by Nityananda on 27.11.20.
//

import Runtime

extension Message {
    init(typeInfo: TypeInfo) throws {
        let name = try typeInfo.compatibleName() + "Message"
        
        let properties: [Property]
        
        if ParticularType(typeInfo.type).isPrimitive {
            properties = []
        } else {
            properties = typeInfo.properties
                .enumerated()
                .compactMap { tuple -> Property? in
                    let (offset, element) = tuple
                    do {
                        let typeInfo = try Runtime.typeInfo(of: element.type)
                        let postfix = ParticularType(element.type).isPrimitive
                            ? ""
                            : "Message"
                        let typeName = try typeInfo.compatibleName() + postfix
                        
                        return Property(
                            isRepeated: ParticularType(typeInfo.type).isArray,
                            name: element.name,
                            typeName: typeName,
                            uniqueNumber: offset
                        )
                    } catch {
                        print(error)
                        return nil
                    }
                }
        }
        
        self.init(
            name: name,
            properties: Set(properties)
        )
    }
}
