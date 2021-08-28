//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import Apodini
import ApodiniREST
import ApodiniUtils
import ApodiniTypeInformation
import ApodiniVaporSupport
import OpenAPIKit

/// Constants for building specification compatible schema names.
enum OpenAPISchemaConstants {
    static let genericsPrefix = "of"
    static let genericsJoiner = "and"
}


// MARK: - MimeType + TypeInformationDefaultConstructor
extension MimeType: TypeInformationDefaultConstructor {
    public static func construct() -> TypeInformation {
        .object(
            name: .init(MimeType.self),
            properties: [
                .init(name: MimeType.CodingKeys.type.stringValue, type: .scalar(.string)),
                .init(name: MimeType.CodingKeys.subtype.stringValue, type: .scalar(.string)),
                .init(name: MimeType.CodingKeys.parameters.stringValue, type: .dictionary(key: .string, value: .scalar(.string)))
            ]
        )
    }
}

// MARK: - Blob + TypeInformationDefaultConstructor
extension Blob: TypeInformationDefaultConstructor {
    public static func construct() -> TypeInformation {
        .scalar(.data)
    }
}

/// Corresponds to `components` section in OpenAPI document
/// See: https://swagger.io/specification/#components-object
class OpenAPIComponentsObjectBuilder {
    private(set) var componentsObject: OpenAPIKit.OpenAPI.Components = .init()
    
    /// Use this function to build a schema for an arbitrary type.
    /// Types built with function are automatically stored into the componentsObject
    /// and thus can be referenced throughout the specification.
    /// In case, the given type is a reference type, the reference to the schema will be returned.
    func buildSchema(for type: Encodable.Type) throws -> JSONSchema {
        let (schema, _) = try buildSchemaWithTitle(for: type)
        return schema
    }
    
    /// For responses, a wrapper object is created as it is returned by the REST API.
    /// Therefore `ResponseContainer`'s CodingKeys are reused.
    /// The resulting JSONSchema is stored in the componentsObject.
    func buildResponse(for type: Encodable.Type) throws -> JSONSchema {
        let (schema, title) = try buildSchemaWithTitle(for: type)
        let schemaName = "\(title)Response"
        let schemaObject: JSONSchema = .object(
            title: schemaName,
            properties: [
                ResponseContainer.CodingKeys.data.rawValue: schema,
                ResponseContainer.CodingKeys.links.rawValue: try buildSchema(for: ResponseContainer.Links.self)
            ])
        if !schemaExists(for: schemaName) {
            saveSchema(name: schemaName, schema: schemaObject)
        }
        return .reference(.component(named: schemaName))
    }
    
    /// In case there is more than one type in HTTP body, a wrapper schema needs to be built.
    /// This function takes a list of types with an associated boolean flag reflecting whether it is optional.
    func buildWrapperSchema(for types: [Codable.Type], with necessities: [Apodini.Necessity]) throws -> JSONSchema {
        let schemasWithTitles: [(JSONSchema, String)] = try types.enumerated().map {
            var (schema, title) = try buildSchemaWithTitle(for: $1)
            if case .optional = necessities[$0] {
                schema = schema.optionalSchemaObject()
            }
            return (schema, title)
        }
        let properties = schemasWithTitles
            .enumerated()
            .reduce(into: [String: JSONSchema]()) {
                // Offset is needed to guarantee distinct property names.
                $0["\($1.element.1)_\($1.offset)"] = $1.element.0
            }
        let schemaName = schemasWithTitles
            .map { $1 }
            .joined(separator: "_")
        let schema: JSONSchema = .object(
            properties: properties
        )
        saveSchema(name: schemaName, schema: schema)
        return .reference(.component(named: schemaName))
    }
}

// MARK: - Utilities for creating and saving schemas into componentsObject
extension OpenAPIComponentsObjectBuilder {
    /// Builds the schema for a type and returns it together with a suitable title.
    private func buildSchemaWithTitle(for type: Any.Type) throws -> (JSONSchema, String) {
        let rootTypeInformation = try TypeInformation(type: type)
        
        rootTypeInformation.allTypes().forEach { typeInformation in
            let schema: JSONSchema = .from(typeInformation: typeInformation)
            let schemaName = typeInformation.jsonSchemaName()
            if schema.isReference && !schemaExists(for: schemaName) {
                let properties = typeInformation.objectProperties.reduce(into: [String: JSONSchema]()) { result, current in
                    result[current.name] = .from(typeInformation: current.type)
                }
                let schemaObject: JSONSchema = .object(title: schema.title, properties: properties)
                saveSchema(name: schemaName, schema: schemaObject)
            }
        }
        
        return (.from(typeInformation: rootTypeInformation), rootTypeInformation.jsonSchemaName(isRoot: true))
    }
    
    /// Saves a schema into componentsObject.
    private func saveSchema(name: String, schema: JSONSchema) {
        componentsObject.schemas[componentKey(for: name)] = schema
    }
    
    /// Checks if schema is already part of componentsObject.
    private func schemaExists(for name: String) -> Bool {
        let internalReference = JSONReference<JSONSchema>.InternalReference.component(name: name)
        return self.componentsObject.contains(internalReference)
    }
    
    /// Creates a componentKey usable for saving the schema into componentsObject.
    private func componentKey(for name: String) -> OpenAPIKit.OpenAPI.ComponentKey {
        guard let componentKey = OpenAPIKit.OpenAPI.ComponentKey(rawValue: name) else {
            fatalError("Failed to set component key \(name) in OpenAPI components.")
        }
        return componentKey
    }
}

// MARK: - TypeInformation + JSONSchemaName
extension TypeInformation {
    func jsonSchemaName(isRoot: Bool = false) -> String {
        let constants = OpenAPISchemaConstants.self
        var schemaName = typeName.absoluteName(constants.genericsPrefix, constants.genericsJoiner)
        
        // The schemaName is prefixed if the root type is .repeated, .dictionary or optional
        if isRoot {
            switch rootType {
            case .repeated:
                schemaName = "Arrayof\(schemaName)"
            case .dictionary:
                schemaName = "Dictionaryof\(schemaName)"
            case .optional:
                schemaName = "Optionalof\(schemaName)"
            default:
                break
            }
        }
        return schemaName
    }
}
