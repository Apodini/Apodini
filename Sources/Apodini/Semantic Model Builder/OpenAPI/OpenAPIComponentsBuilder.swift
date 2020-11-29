//
//  OpenAPIComponentsBuilder.swift
//  
//
//  Created by Lorena Schlesinger on 28.11.20.
//

import OpenAPIKit
import Runtime
import Foundation

class OpenAPIComponentsBuilder {
    var components: OpenAPI.Components = .init(
        schemas: [:],
        responses: [:],
        parameters: [:],
        examples: [:],
        requestBodies: [:],
        headers: [:],
        securitySchemes: [:],
        callbacks: [:],
        vendorExtensions: [:]
    )
    
    func findOrCreateSchema(from type: Any.Type) throws -> JSONSchema {
        guard let reflectedType = reflectType(type) else {
            throw OpenAPIComponentBuilderError("Could not reflect type.")
        }
        return recursivelyCreateSchemas(from: reflectedType)
    }
    
    private func reflectType(_ type: Any.Type) -> TypeInfo? {
        var info: TypeInfo? = nil
        do {
            info = try typeInfo(of: type)
        }
        catch {
            print(error)
        }
        return info
    }
    
    private func recursivelyCreateSchemas(from type: TypeInfo) -> JSONSchema {
            
        // if primitive -> return JSONSchema directly
        if type.isPrimitive {
            return type.openAPIJSONSchema
        }
        
        // if already in components -> return JSONReference
        let internalReference = JSONReference<JSONSchema>.InternalReference.component(name: type.mangledName)
        let schemaReference = JSONReference.internal(internalReference)
        if self.components.contains(internalReference) {
            return .reference(schemaReference)
        }
        
        // if wrapped type (e.g., Either, EventLoopFuture) -> anyOf? or only [0]
        if type.isWrapperType {
            if type.wrappedTypes.count > 1 {
                return .any(of: type.wrappedTypes.map { recursivelyCreateSchemas(from: $0)})
            }
            return recursivelyCreateSchemas(from: type.wrappedTypes[0])
        }
        
        // if array -> array()
        if type.isArray {
            return .array(items: recursivelyCreateSchemas(from: type.wrappedTypes[0]))
        }
        
        // if dictionary -> object()
        if type.isDictionary {
            return .object(additionalProperties: .init(recursivelyCreateSchemas(from: type.wrappedTypes[1])))
        }
        
        // TODO: if tuple -> (x,y) -> {"0": x, "1": y}
        var properties: [String : JSONSchema] = [:]
        // in any other case: loop over typeInfo of properties
        for property in type.properties {
            var propertyTypeInfo: TypeInfo
            do {
                propertyTypeInfo = try typeInfo(of: property.type)
            }
            catch {
                print(error)
                continue
            }
            // [name: schema] -> call `recursivelyCreateSchemas(propertyTypeInfo)` to traverse nested types and generate schemas
            // add to schema properties
            properties[property.name] = recursivelyCreateSchemas(from: propertyTypeInfo)
        }
        
        // add created schema
        var schema = JSONSchema.object(properties: properties)
        self.components.schemas[OpenAPI.ComponentKey.init(rawValue: type.mangledName)!] = schema
    
        return .reference(schemaReference)
    }
}
