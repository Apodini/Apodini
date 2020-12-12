//
//  File.swift
//  
//
//  Created by Nityananda on 11.12.20.
//

import Runtime

struct EnrichedInfo {
    let typeInfo: TypeInfo
    let propertyInfo: PropertyInfo?
    let propertiesOffset: Int?
}

extension EnrichedInfo {
    static func tree<T>(_ type: T.Type) throws -> Tree<EnrichedInfo> {
        let typeInfo = try Runtime.typeInfo(of: type)
        let root = EnrichedInfo(
            typeInfo: typeInfo,
            propertyInfo: nil,
            propertiesOffset: nil)
        
        return Node(root) { info in
            info.typeInfo.properties
                .enumerated()
                .compactMap { (offset, propertyInfo) in
                    do {
                        let typeInfo = try Runtime.typeInfo(of: propertyInfo.type)
                        return EnrichedInfo(
                            typeInfo: typeInfo,
                            propertyInfo: propertyInfo,
                            propertiesOffset: offset + 1
                        )
                    } catch {
                        print(error)
                        return nil
                    }
                }
        }
    }
}
