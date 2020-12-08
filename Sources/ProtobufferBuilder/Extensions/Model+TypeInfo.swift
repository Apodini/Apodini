//
//  File.swift
//  
//
//  Created by Nityananda on 27.11.20.
//

import Runtime

extension Message {
    init(typeInfo: TypeInfo) throws {
        let name = try typeInfo.compatibleName()
        
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
                        let typeName = try typeInfo.compatibleName()
                        
                        return Property(
                            isRepeated: typeInfo.isArray,
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
