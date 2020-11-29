//
//  TypeInfo+OpenAPI.swift
//  
//
//  Created by Lorena Schlesinger on 28.11.20.
//

import OpenAPIKit
import Runtime
import Foundation

/// there are some `Runtime.Kind` types -> struct (includes `Array`, `Dictionary`, `Int`, `Double`, `Bool` ), class, tuple
extension TypeInfo {
    var propertyTypeInfo: [TypeInfo] {
        properties.compactMap {
            do {
                return try typeInfo(of: $0.type)
            } catch {
                return nil
            }
        }
    }
    
    var isWrapperType: Bool {
        genericTypes.count > 0 &&
            ["EventLoopFuture", "Either", "Optional"].contains(where: {
                name.contains($0)
            })
    }
    
    var wrappedTypes: [TypeInfo] {
        genericTypes.compactMap {
            do {
                return try typeInfo(of: $0)
            } catch {
                return nil
            }
        }
    }
    
    var isPrimitive: Bool {
        // e.g., Int, Swift.Int, ...
        ["Int", "Bool", "Double", "String"].contains(where: {
            name.hasPrefix($0) || name.hasSuffix($0)
        })
    }
    
    var isArray: Bool {
        ["Array"].contains(where: {
            name.contains($0)
        })
    }
    
    var isDictionary: Bool {
        // see https://github.com/apple/swift/blob/main/stdlib/public/core/Dictionary.swift
        ["Dictionary", "_Variant"].contains(where: {
            name.contains($0)
        })
    }
    
    var openAPIJSONSchema: JSONSchema {
        switch type {
        case is Int.Type:
            return .integer()
        case is Bool.Type:
            return .boolean()
        case is String.Type:
            return .string()
        case is Double.Type:
            return .number(format: .double)
        case is Date.Type:
            return .string(format: .date)
        default:
            print("OpenAPI schema not found for type \(type).")
            // throw OpenAPISchemaError()
            return .object()
        }
        
    }
}
