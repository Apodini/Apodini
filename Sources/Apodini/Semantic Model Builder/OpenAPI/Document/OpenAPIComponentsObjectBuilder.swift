//
//  Created by Lorena Schlesinger on 28.11.20.
//

@_implementationOnly import OpenAPIKit
import Foundation

/// Corresponds to `components` section in OpenAPI document
/// See: https://swagger.io/specification/#components-object
class OpenAPIComponentsObjectBuilder {
    var componentsObject: OpenAPI.Components = .init(
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

    /// In case more than one type in HTTP body, build wrapper schema.
    /// This function takes a list of types with an associated boolean flag reflecting whether it is optional.
    func buildWrapperSchema(for types: [Codable.Type], with necessities: [Necessity]) throws -> JSONSchema {
        let trees: [Node<EnrichedInfo>] = try types.map {
            guard let node = try Self.node($0) else {
                throw OpenAPIComponentBuilderError("Could not reflect type \($0).")
            }
            return node
        }
        let properties = trees
            .enumerated()
            .reduce(into: [String: JSONSchema]()) {
                var schema: JSONSchema = $1.element.contextMap(contextMapNode).value
                schema = necessities[$1.offset] == .optional ? schema.optionalSchemaObject() : schema
                // we need the offset to guarantee distinct property names
                return $0["\($1.element.value.typeInfo.mangledName)_\($1.offset)"] = schema
            }
        let schemaName = trees
            .map {
                $0.value.typeInfo.mangledName
            }
            .joined(separator: "_")
        let schema = JSONSchema.object(
            properties: properties
        )
        self.componentsObject.schemas[componentKey(for: schemaName)] = schema
        return JSONSchema.reference(.component(named: schemaName))
    }

    func buildResponse(for type: Encodable.Type) throws -> JSONSchema {
        let schema = try buildSchema(for: type)
        return .object(properties: [
            ResponseContainer.CodingKeys.data.rawValue: schema,
            ResponseContainer.CodingKeys.links.rawValue: try buildSchema(for: ResponseContainer.Links.self)
        ])
    }

    func buildSchema(for type: Encodable.Type) throws -> JSONSchema {
        let node: Node<JSONSchema>? = try Self.node(type)?
            .contextMap(contextMapNode)
        guard let schema = node?.value else {
            throw OpenAPIComponentBuilderError("Could not reflect type.")
        }
        return schema
    }

    private func contextMapNode(node: Node<EnrichedInfo>) -> JSONSchema {
        var schema = mapInfo(node)
        let schemaName = node.value.typeInfo.mangledName

        if schema.isReference && !schemaExists(for: schemaName) {
            var properties: [String: JSONSchema] = [:]
            for child in node.children {
                if let propertyInfo = child.value.propertyInfo {
                    properties[propertyInfo.name] = mapInfo(child)
                }
            }
            let schemaObject = JSONSchema.object(properties: properties)
            self.componentsObject.schemas[componentKey(for: schemaName)] = schemaObject
        }
        return schema
    }

    private func mapInfo(_ node: Node<EnrichedInfo>) -> JSONSchema {
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
            let schemaName = node.value.typeInfo.mangledName
            schema = JSONSchema.reference(.component(named: schemaName))
        }
        if isEnum(node.value.typeInfo.type) {
            schema = .string(allowedValues: node.value.typeInfo.cases.map { .init($0.name) })
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

    private func schemaExists(for name: String) -> Bool {
        let internalReference = JSONReference<JSONSchema>.InternalReference.component(name: name)
        return self.componentsObject.contains(internalReference)
    }

    private func componentKey(for name: String) -> OpenAPI.ComponentKey {
        guard let componentKey = OpenAPI.ComponentKey(rawValue: name) else {
            fatalError("Failed to set component key \(name) in OpenAPI components.")
        }
        return componentKey
    }
}


private extension OpenAPIComponentsObjectBuilder {
    static func node(_ type: Any.Type) throws -> Node<EnrichedInfo>? {
        let node = try EnrichedInfo.node(type)
            .edited(handleOptional)?
            .edited(handleArray)?
            .edited(handleDictionary)?
            .edited(handlePrimitiveType)?
            .edited(handleUUID)
        return node
    }
}
