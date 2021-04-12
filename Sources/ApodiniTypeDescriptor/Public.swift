//
//  File.swift
//  
//
//  Created by Eldi Cano on 12.04.21.
//

import Foundation

/// Returns a type descriptor object from an encodable type
public func typeDescriptor<T: Encodable>(_ type: T.Type) throws -> TypeDescriptor {
    let typeInstance = try instance(T.self) // creating the instance from the type
    
    let encoder = _JSONEncoder(typeDescriptor: try .init(type))
    _ = try encoder.box_(typeInstance)
    
    return encoder.typeDescriptor
}
