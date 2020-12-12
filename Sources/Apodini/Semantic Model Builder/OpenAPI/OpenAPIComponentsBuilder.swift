//
//  OpenAPIComponentsBuilder.swift
//  
//
//  Created by Lorena Schlesinger on 28.11.20.
//

import OpenAPIKit
import Runtime
import Foundation

/// Corresponds to `components` section in OpenAPI document
/// See: https://swagger.io/specification/#components-object
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
    
    func buildSchema(for type: Any.Type) throws -> JSONSchema {
        guard let reflectedType = reflectType(type) else {
            throw OpenAPIComponentBuilderError("Could not reflect type.")
        }
        return recursivelyBuildSchema(for: reflectedType)
    }
    
    private func reflectType(_ type: Any.Type) -> TypeInfo? {
        var info: TypeInfo?
        do {
            info = try typeInfo(of: type)
        } catch {
            // TODO: come up with good use of throwables
            print(error)
        }
        return info
    }
    
    private func recursivelyBuildSchema(for type: TypeInfo) -> JSONSchema {
        if type.isPrimitive {
            return type.openAPIJSONSchema
        }
        
        let schemaName = type.mangledName
        let (schemaReference, schemaExists) = findOrCreateSchemaReference(for: schemaName)
        if schemaExists {
            return schemaReference
        }
        
        if type.isWrapperType {
            if type.wrappedTypes.count > 1 {
                return .any(of: type.wrappedTypes.map { recursivelyBuildSchema(for: $0) })
            }
            // TODO: multiple generic types?
            return recursivelyBuildSchema(for: type.wrappedTypes[0])
        }
        
        // TODO: what about sets/lists?
        if type.isArray {
            return .array(
                items: recursivelyBuildSchema(for: type.wrappedTypes[0])
            )
        }
        
        if type.isDictionary {
            return .object(
                additionalProperties: .init(
                    recursivelyBuildSchema(for: type.wrappedTypes[1])
                )
            )
        }
        
        // TODO: handling of tuple TBD; e.g., (x,y) -> {"0": x, "1": y}
        
        var properties: [String: JSONSchema] = [:]
        for property in type.properties {
            guard let propertyTypeInfo = reflectType(property.type) else {
                // if type info cannot be obtained, exclude this property
                continue
            }
            properties[property.name] = recursivelyBuildSchema(for: propertyTypeInfo)
        }
        
        self.components.schemas[OpenAPI.ComponentKey(rawValue: schemaName)!] = JSONSchema.object(properties: properties)
        
        return schemaReference
    }
    
    private func findOrCreateSchemaReference(for name: String) -> (JSONSchema, Bool) {
        let internalReference = JSONReference<JSONSchema>.InternalReference.component(name: name)
        let reference = JSONReference.internal(internalReference)
        let schemaReference = JSONSchema.reference(reference)
        if self.components.contains(internalReference) {
            return (schemaReference, true)
        }
        return (schemaReference, false)
    }
}
