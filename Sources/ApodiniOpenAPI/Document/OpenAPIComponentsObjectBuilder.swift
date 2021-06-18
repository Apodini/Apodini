//
//  Created by Lorena Schlesinger on 28.11.20.
//

import Foundation
import Apodini
import ApodiniREST
import ApodiniUtils
import ApodiniTypeReflection
import ApodiniVaporSupport
import OpenAPIKit

/// Constants for building specification compatible schema names.
enum OpenAPISchemaConstants {
    static let replaceOpenAngleBracket = "of"
    static let replaceCloseAngleBracket = ""
    static let replaceCommaSeparation = "and"
    static let allowedRecursionDepth = 15
}

/// Corresponds to `components` section in OpenAPI document
/// See: https://swagger.io/specification/#components-object
class OpenAPIComponentsObjectBuilder {
    var componentsObject: OpenAPIKit.OpenAPI.Components = .init(
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
        if type == Blob.self {
            return .string(format: .binary, required: true)
        } else {
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
    }
    
    /// In case there is more than one type in HTTP body, a wrapper schema needs to be built.
    /// This function takes a list of types with an associated boolean flag reflecting whether it is optional.
    func buildWrapperSchema(for types: [Codable.Type], with necessities: [Necessity]) throws -> JSONSchema {
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
            .map {
                $1
            }
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
        let node: Node<ReflectionInfo> = try Self.node(type)
        let schemaNode = node.contextMap { (node: Node<ReflectionInfo>) -> JSONSchema in
            let schema = deriveSchemaFromReflectionInfo(node)
            let schemaName = createSchemaName(for: node)
            
            // If there is a reference type that is not yet saved into the
            // componentsObject, a new schema is created and saved.
            if schema.isReference && !schemaExists(for: schemaName) {
                var properties: [String: JSONSchema] = [:]
                for child in node.children {
                    if let propertyInfo = child.value.propertyInfo {
                        properties[propertyInfo.name] = deriveSchemaFromReflectionInfo(child)
                    }
                }
                let schemaObject: JSONSchema = .object(title: schema.title, properties: properties)
                saveSchema(name: schemaName, schema: schemaObject)
            }
            return schema
        }
        let title = createSchemaName(for: node, root: true)
        return (schemaNode.value, title)
    }
    
    /// Saves a schema into componentsObject.
    private func saveSchema(name: String, schema: JSONSchema) {
        self.componentsObject.schemas[componentKey(for: name)] = schema
    }
    
    /// Creates specification compliant schema names.
    private func createSchemaName(for node: Node<ReflectionInfo>, root: Bool = false) -> String {
        var schemaName: String
        if !node.value.typeInfo.genericTypes.isEmpty {
            let openAPICompliantName = node.value.typeInfo.name
                .replacingOccurrences(of: "<", with: OpenAPISchemaConstants.replaceOpenAngleBracket)
                .replacingOccurrences(of: ">", with: OpenAPISchemaConstants.replaceCloseAngleBracket)
                .replacingOccurrences(of: ", ", with: OpenAPISchemaConstants.replaceCommaSeparation)
            schemaName = openAPICompliantName
        } else {
            schemaName = node.value.typeInfo.mangledName
        }
        
        // The schemaName is prefixed if the root type cardinality != .exactlyOne.
        if root {
            switch node.value.cardinality {
            case .zeroToOne:
                schemaName = "Optionalof\(schemaName)"
            case .zeroToMany(let context):
                switch context {
                case .dictionary:
                    schemaName = "Dictionaryof\(schemaName)"
                case .array:
                    schemaName = "Arrayof\(schemaName)"
                }
            default:
                return schemaName
            }
        }
        
        return schemaName
    }
    
    /// Constructs a schema with type specific attributes, e.g. optional.
    private func deriveSchemaFromReflectionInfo(_ node: Node<ReflectionInfo>) -> JSONSchema {
        let isPrimitive = node.children.isEmpty
        let isOptional = node.value.cardinality == .zeroToOne
        let isArray = node.value.cardinality == .zeroToMany(.array)
        let isDictionary: Bool = {
            if case .zeroToMany(.dictionary) = node.value.cardinality {
                return true
            }
            return false
        }()
        
        var schema: JSONSchema
        
        if isPrimitive {
            schema = JSONSchema.from(node.value.typeInfo.type, defaultType: .object)
        } else {
            let schemaName = createSchemaName(for: node)
            schema = .reference(.component(named: schemaName))
        }
        if isEnum(node.value.typeInfo.type) {
            schema = .string(allowedValues: node.value.typeInfo.cases.map {
                .init($0.name)
            })
        }
        if isDictionary {
            schema = .object(additionalProperties: .init(schema))
        }
        if isArray {
            schema = .array(items: schema)
        }
        if isOptional {
            schema = schema.optionalSchemaObject()
        }
        return schema
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

// MARK: - Type reflection
extension OpenAPIComponentsObjectBuilder {
    /// Creates a type tree for a certain type using reflection.
    static func node(_ type: Any.Type) throws -> Node<ReflectionInfo> {
        let node = try ReflectionInfo.node(type)
        var counter = 0
        return try recursiveEdit(node: node, counter: &counter)
    }
    
    /// Recursively reflects types in a type tree and adjusts them.
    private static func recursiveEdit(node: Node<ReflectionInfo>, counter: inout Int) throws -> Node<ReflectionInfo> {
        if counter > OpenAPISchemaConstants.allowedRecursionDepth {
            fatalError("Error occurred during transfering tree of nodes with type \(node.value.typeInfo.name). The recursion depth has exceeded the critical value of \(OpenAPISchemaConstants.allowedRecursionDepth).")
        }
        counter += 1
        let before = node.collectValues()
        guard let newNode = try node
                .edited(handleOptional)?
                .edited(handleArray)?
                .edited(handleDictionary)?
                .edited(handlePrimitiveType)?
                .edited(handleUUID)
        else {
            fatalError("Error occurred during transforming tree of nodes with type \(node.value.typeInfo.name).")
        }
        let after = newNode.collectValues()
        return after != before ? try recursiveEdit(node: newNode, counter: &counter) : node
    }
}
