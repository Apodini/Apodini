//
//  File.swift
//  
//
//  Created by Nityananda on 27.11.20.
//

import Runtime

struct Exception: Error {
    let message: String
}

extension GRPCMessage {
    init(typeInfo: TypeInfo) throws {
        let name = try typeInfo.kind.nameStrategy(typeInfo)
        
        let properties = typeInfo.properties
            .enumerated()
            .compactMap { (tuple) -> GRPCMessage.Property? in
                let (offset, element) = tuple
                do {
                    let typeName = try Runtime.typeInfo(of: element.type).name
                    
                    return GRPCMessage.Property(
                        name: element.name,
                        typeName: typeName,
                        uniqueNumber: offset
                    )
                } catch {
                    print(error)
                    return nil
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
            return { $0.name }
        case .tuple:
            return Self.tuple
        default:
            return { _ in throw Exception(message: "Kind: \(self) is not supported.") }
        }
    }
    
    static func tuple(typeInfo: TypeInfo) throws -> String {
        if typeInfo.type == Void.self {
            return "VoidMessage"
        } else {
            throw Exception(message: "Tuple: \(typeInfo.type) is not supported.")
        }
    }
}
