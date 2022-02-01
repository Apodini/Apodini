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
import OpenAPIKit

/// Constants for building specification compatible schema names.
enum OpenAPISchemaConstants {
    static let genericsPrefix = "of"
    static let genericsJoiner = "and"
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

        // OpenAPIKit stores the requiredness of property INSIDE the property and not in the .object schema.
        // Therefore, having a .reference property which is optional DOES NOT WORK.
        // This is something which will/is addressed in an alpha version of OpenAPIKit.
        // To workaround that, we will just dereference such objects.
        var optionalObjectProperties: [String: [String]] = [:]

        var pendingModifications: [OpenAPIKit.OpenAPI.ComponentKey: JSONSchemeModification] = [:]

        rootTypeInformation.allTypes().forEach { typeInformation in
            let schema: JSONSchema = .from(typeInformation: typeInformation)
            let schemaName = typeInformation.jsonSchemaName()

            if schema.isReference && !schemaExists(for: schemaName) {
                let properties = typeInformation.objectProperties.reduce(into: [String: JSONSchema]()) { result, current in
                    let schema: JSONSchema = .from(typeInformation: current.type)
                    result[current.name] = schema

                    if current.type.isOptional && schema.isReference {
                        optionalObjectProperties[schemaName, default: []].append(current.name)
                    }
                }

                var pendingModification: JSONSchemeModification?

                let schemaObject: JSONSchema = .object(title: schema.title, properties: properties)
                    .evaluateModifications(
                        containedIn: typeInformation.context,
                        writingPendingPropertyProcessingInto: &pendingModification
                    )

                let key = saveSchema(name: schemaName, schema: schemaObject)

                if let pendingModification = pendingModification {
                    pendingModifications[key] = pendingModification
                }
            }
        }

        for (key, properties) in optionalObjectProperties {
            let updatedSchema = try fixOptionalObjectProperties(for: key, optionalObjectProperties: properties)
            componentsObject.schemas[.init(stringLiteral: key)] = updatedSchema
        }

        // property modifications are also evaluated last, as they might overwrite metadata inside the type.
        for (key, modification) in pendingModifications {
            let resultingScheme = try modification.completePendingModifications(for: key, in: componentsObject)
            componentsObject.schemas[key] = resultingScheme // update the scheme (properties might have changed)
        }

        // below will always generate a .reference or something without a `Context`.
        // Therefore everything is fine and we don't need to evaluate modifications.
        return (.from(typeInformation: rootTypeInformation), rootTypeInformation.jsonSchemaName(isRoot: true))
    }
    
    /// Saves a schema into componentsObject.
    @discardableResult
    private func saveSchema(name: String, schema: JSONSchema) -> OpenAPIKit.OpenAPI.ComponentKey {
        let key = componentKey(for: name)
        componentsObject.schemas[key] = schema
        return key
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

    private func fixOptionalObjectProperties(for key: String, optionalObjectProperties: [String]) throws -> JSONSchema {
        guard let schema = componentsObject.schemas[.init(stringLiteral: key)] else {
            fatalError("Schema \(key) got lost. Tried evaluating property modifications.")
        }
        guard case let .object(_, objectContext) = schema else {
            preconditionFailure("Unexpected non object with properties!")
        }

        var updatedProperties: [String: JSONSchema] = objectContext.properties

        for propertyName in optionalObjectProperties {
            guard let property = try updatedProperties[propertyName]?.rootDereference(in: componentsObject) else {
                fatalError("Unexpected property: \(propertyName)!")
            }
            precondition(property.isObject, "Found non object property!")

            let propertyModification = JSONSchemeModification(
                root: PropertyModification(context: CoreContext.self, property: .required, value: false)
            )

            updatedProperties[propertyName] = propertyModification(on: property)
        }

        let modification = JSONSchemeModification(
            root: PropertyModification(context: ObjectContext.self, property: .properties, value: updatedProperties)
        )


        return modification(on: schema)
    }
}

// MARK: Security Scheme
extension OpenAPIComponentsObjectBuilder {
    func addSecurityScheme(key: OpenAPIKit.OpenAPI.ComponentKey, scheme: OpenAPIKit.OpenAPI.SecurityScheme) {
        componentsObject.securitySchemes[key] = scheme
    }
}

// MARK: - TypeInformation + JSONSchemaName
extension TypeInformation {
    func jsonSchemaName(isRoot: Bool = false) -> String {
        let constants = OpenAPISchemaConstants.self
        var schemaName = typeName.buildName(genericsStart: constants.genericsPrefix, genericsDelimiter: constants.genericsJoiner)
        
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
