//
//  File.swift
//  
//
//  Created by Eldi Cano on 12.04.21.
//

import Foundation

public class TypeDescriptor {
    let name: String
    let typeWrapper: TypeWrapper
    var properties: [Property]
    
    convenience init<T: Encodable>(_ type: T.Type) throws {
        self.init(
            name: String(describing: T.self),
            typeWrapper: try ApodiniTypeDescriptor.typeWrapper(for: T.self),
            properties: []
        )
    }
    
    init(name: String, typeWrapper: TypeWrapper, properties: [Property]) {
        self.name = name
        self.typeWrapper = typeWrapper
        self.properties = properties
    }
    
    func register(at paths: [String], typeWrapper: TypeWrapper) {
        if paths.count == 1, let first = paths.first {
            properties.append(.init(parent: nil, offset: properties.count, path: first, type: typeWrapper))
        } else {
            let parentPathComponents = Array(paths.dropLast())
            var matched: Property?
            
            properties.forEach {
                if let property = $0.property(with: parentPathComponents) {
                    matched = property
                }
            }
            
            if let matched = matched, let last = paths.last {
                matched.addProperty(.init(parent: matched, offset: matched.properties.count, path: last, type: typeWrapper))
            }
        }
    }
}

extension TypeDescriptor: CustomDebugStringConvertible {
    public var debugDescription: String {
        var description = "\(typeWrapper.debugDescription)"
        properties.forEach { description.append("\n\($0.debugDescription)") }
        return description
    }
}
