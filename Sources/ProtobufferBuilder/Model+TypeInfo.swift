//
//  File.swift
//  
//
//  Created by Nityananda on 27.11.20.
//

import Runtime

extension Message {
    init(typeInfo: TypeInfo) throws {
        let name = try typeInfo.kind.nameStrategy(typeInfo)
        
        let properties: [Property]
        
        if isPrimitive(typeInfo.type) {
            properties = []
        } else {
            properties = typeInfo.properties
                .enumerated()
                .compactMap { tuple -> Property? in
                    let (offset, element) = tuple
                    do {
                        let typeInfo = try Runtime.typeInfo(of: element.type)
                        let typeName = try compatibleGenericName(typeInfo)
                        
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

private extension Kind {
    var nameStrategy: (TypeInfo) throws -> String {
        switch self {
        case .struct, .class:
            return compatibleGenericName
        case .tuple:
            return Self.tuple
        default:
            return { _ in throw Exception(message: "Kind: \(self) is not supported.") }
        }
    }
    
    static func tuple(typeInfo: TypeInfo) throws -> String {
        if typeInfo.type == Void.self {
            return "Void"
        } else {
            throw Exception(message: "Tuple: \(typeInfo.type) is not supported.")
        }
    }
}
