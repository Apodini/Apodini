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
        
        let properties: [Message.Property]
        
        if isPrimitive(typeInfo.type) {
            properties = []
        } else {
            properties = typeInfo.properties
                .enumerated()
                .compactMap { (tuple) -> Message.Property? in
                    let (offset, element) = tuple
                    do {
                        let typeName = try spellOutGeneric(
                            typeInfo: try Runtime.typeInfo(of: element.type)
                        )
                        
                        return Message.Property(
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
            return spellOutGeneric(typeInfo:)
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

private func spellOutGeneric(typeInfo: TypeInfo) throws -> String {
    let tree: Tree = try Node(typeInfo) { typeInfo in
        try typeInfo.genericTypes.map { element in
            try Runtime.typeInfo(of: element)
        }
    }
    
    let name = tree.reduce(into: "") { (result, value) in
        let next = value.name.prefix { $0 != "<" }
        result += result.isEmpty
            ? next
            : "Of\(next)"
    }
    
    return name
}
