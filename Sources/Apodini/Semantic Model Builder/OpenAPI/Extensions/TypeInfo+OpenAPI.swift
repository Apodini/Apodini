//
//  Created by Lorena Schlesinger on 28.11.20.
//

@_implementationOnly import OpenAPIKit
@_implementationOnly import Runtime
import Foundation
import NIO

// MARK: Constants
let primitiveTypes: [Any.Type] = [
    Int.self,
    Int8.self,
    Int16.self,
    Int32.self,
    Int64.self,
    UInt.self,
    UInt8.self,
    UInt16.self,
    UInt32.self,
    UInt64.self,
    Bool.self,
    Double.self,
    Float.self,
    Float32.self,
    Float64.self,
    String.self,
    UUID.self // TODO: maybe treat this elsewhere
]

// TODO: improve this also for Array, Dictionary, and wrapperTypes


// MARK: TypeInfo
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
        !genericTypes.isEmpty &&
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
        primitiveTypes.contains(where: {
            $0 == self.type
        })
    }

    var isArray: Bool {
        ["Array"].contains(where: {
            name.contains($0)
        })
    }

    var isDictionary: Bool {
        ["Dictionary"].contains(where: {
            name.contains($0)
        })
    }

    var openAPIJSONSchema: JSONSchema {
        switch type {
        case is Int.Type:
            return .integer
        case is Bool.Type:
            return .boolean
        case is String.Type:
            return .string
        case is Double.Type:
            return .number(format: .double)
        case is Date.Type:
            return .string(format: .date)
        case is UUID.Type:
            return .string
        default:
            print("OpenAPI schema not found for type \(type).")
            return .object
        }
    }
}
