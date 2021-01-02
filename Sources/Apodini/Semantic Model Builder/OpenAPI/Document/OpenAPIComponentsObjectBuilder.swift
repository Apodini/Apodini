//
//  Created by Lorena Schlesinger on 28.11.20.
//

@_implementationOnly import OpenAPIKit
@_implementationOnly import Runtime
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
                throw OpenAPIComponentBuilderError("Could not reflect type.")
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
        let schemaName = trees.map {
            $0.value.typeInfo.mangledName
        }.joined(separator: "_")
        let schema = JSONSchema.object(
                properties: properties
        )
        self.componentsObject.schemas[componentKey(for: schemaName)] = schema
        return JSONSchema.reference(.component(named: schemaName))
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
        // TODO: we should also handle optional arrays (e.g., array of cardinalities)
        let isOptional = node.value.cardinality == .zeroToOne
        let isArray = node.value.cardinality == .zeroToMany
        let isPrimitive = node.children.isEmpty

        let schema = mapInfo(
                node.value,
                isPrimitive: isPrimitive,
                isOptional: isOptional,
                isArray: isArray)

        let schemaName = node.value.typeInfo.mangledName
        if !isPrimitive && !schemaExists(for: schemaName) {
            var properties: [String: JSONSchema] = [:]
            for child in node.children {
                if let propertyInfo = child.value.propertyInfo {
                    properties[propertyInfo.name] = mapInfo(child.value,
                            isPrimitive: child.children.isEmpty,
                            isOptional: child.value.cardinality == .zeroToOne,
                            isArray: child.value.cardinality == .zeroToMany)
                }
            }
            self.componentsObject.schemas[componentKey(for: schemaName)] = JSONSchema.object(properties: properties)
        }

        return schema
    }

    private func mapInfo(_ info: EnrichedInfo, isPrimitive: Bool, isOptional: Bool, isArray: Bool) -> JSONSchema {
        var value: JSONSchema
        if isPrimitive {
            value = info.typeInfo.openAPIJSONSchema
        } else {
            let schemaName = info.typeInfo.mangledName
            value = JSONSchema.reference(.component(named: schemaName))
        }
        if isArray {
            value = .array(items: value)
        }
        if isOptional {
            value = value.optionalSchemaObject()
        }
        return value
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
                .edited(handlePrimitiveType)
        return node
    }
}
