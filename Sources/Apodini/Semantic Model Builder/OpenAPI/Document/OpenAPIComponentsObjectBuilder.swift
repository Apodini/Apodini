//
//  Created by Lorena Schlesinger on 28.11.20.
//

@_implementationOnly import OpenAPIKit
import Foundation

enum OpenAPISchemaConstants {
    static let replaceOpenAngleBracket = "of"
    static let replaceCloseAngleBracket = ""
    static let replaceCommaSeparation = "and"
    static let allowedRecursionDepth = 15
}

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
        let schema = mapInfo(node)
        let schemaName = createSchemaName(for: node)

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

    private func createSchemaName(for node: Node<EnrichedInfo>) -> String {
        if !node.value.typeInfo.genericTypes.isEmpty {
            let openAPICompliantName = node.value.typeInfo.name
                .replacingOccurrences(of: "<", with: OpenAPISchemaConstants.replaceOpenAngleBracket)
                .replacingOccurrences(of: ">", with: OpenAPISchemaConstants.replaceCloseAngleBracket)
                .replacingOccurrences(of: ", ", with: OpenAPISchemaConstants.replaceCommaSeparation)
            return openAPICompliantName
        } else {
            return node.value.typeInfo.mangledName
        }
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
            let schemaName = createSchemaName(for: node)
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

extension OpenAPIComponentsObjectBuilder {
    static func node(_ type: Any.Type) throws -> Node<EnrichedInfo>? {
        let node = try EnrichedInfo.node(type)
        var counter = 0
        return try recursiveEdit(node: node, counter: &counter)
    }

    private static func recursiveEdit(node: Node<EnrichedInfo>, counter: inout Int) throws -> Node<EnrichedInfo> {
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
