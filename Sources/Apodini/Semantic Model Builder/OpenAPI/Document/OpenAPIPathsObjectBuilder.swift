//
//  Created by Lorena Schlesinger on 15.11.20.
//

@_implementationOnly import OpenAPIKit

/// Utility to convert `_PathComponent`s to `OpenAPI.Path` format.
struct OpenAPIPathBuilder: PathBuilder {
    lazy var path: OpenAPI.Path = OpenAPI.Path(stringLiteral: self.components.joined(separator: "/"))
    var components: [String] = []
    let parameters: [AnyEndpointParameter]

    init(_ pathComponents: [_PathComponent], parameters: [AnyEndpointParameter]) {
        self.parameters = parameters
        for pathComponent in pathComponents {
            pathComponent.append(to: &self)
        }
    }

    mutating func append<T>(_ parameter: Parameter<T>) {
        guard let param = parameters.first(where: {
            $0.id == parameter.id
        }) else {
            fatalError("Path contains parameter which cannot be found in endpoint's parameters.")
        }
        components.append("{\(param.name)}")
    }

    mutating func append(_ string: String) {
        components.append(string)
    }
}

/// Corresponds to `paths` section in OpenAPI document.
/// See: https://swagger.io/specification/#paths-object
struct OpenAPIPathsObjectBuilder {
    var pathsObject: OpenAPI.PathItem.Map = [:]
    let componentsObjectBuilder: OpenAPIComponentsObjectBuilder

    init(componentsObjectBuilder: inout OpenAPIComponentsObjectBuilder) {
        self.componentsObjectBuilder = componentsObjectBuilder
    }

    /// https://swagger.io/specification/#path-item-object
    mutating func addPathItem<C: Component>(from endpoint: Endpoint<C>) {
        // Get OpenAPI-compliant path representation.
        var pathBuilder = OpenAPIPathBuilder(endpoint.absolutePath, parameters: endpoint.parameters)
        let path = pathBuilder.path

        // Get or create `PathItem`.
        var pathItem = pathsObject[path] ?? OpenAPI.PathItem()

        // Get `OpenAPI.HttpMethod` and `OpenAPI.Operation` from endpoint.
        let httpMethod = endpoint.operation.openAPIHttpMethod
        let operation = buildPathItemOperationObject(from: endpoint)
        pathItem.set(operation: operation, for: httpMethod)

        // Add (or override) `PathItem` to map of paths.
        pathsObject[path] = pathItem
    }
}

private extension OpenAPIPathsObjectBuilder {
    /// https://swagger.io/specification/#operation-object
    mutating func buildPathItemOperationObject<C: Component>(from endpoint: Endpoint<C>) -> OpenAPI.Operation {
        // Get `Parameter.Array` from existing `query` or `path` parameters.
        let parameters: OpenAPI.Parameter.Array = buildParametersArray(from: endpoint.parameters)

        // Get `OpenAPI.Request` body object containing HTTP body types.
        let requestBody: OpenAPI.Request? = buildRequestBodyObject(from: endpoint.parameters)

        // Get `OpenAPI.Response.Map` containing all possible HTTP responses mapped to their status code.
        let responses: OpenAPI.Response.Map = buildResponsesObject(from: endpoint.responseType)

        return OpenAPI.Operation(
            parameters: parameters,
            requestBody: requestBody,
            responses: responses
        )
    }

    /// https://swagger.io/specification/#parameter-object
    mutating func buildParametersArray(from parameters: [AnyEndpointParameter]) -> OpenAPI.Parameter.Array {
        parameters.compactMap {
            if let context = OpenAPI.Parameter.Context($0) {
                return Either.parameter(name: $0.name, context: context, schema: JSONSchema.from($0.propertyType), description: $0.description)
            }
            return nil
        }
    }

    /// https://swagger.io/specification/#request-body-object
    mutating func buildRequestBodyObject(from parameters: [AnyEndpointParameter]) -> OpenAPI.Request? {
        var requestBody: OpenAPI.Request?
        let contentParameters = parameters.filter {
            $0.kind == .content
        }
        var requestJSONSchema: JSONSchema?
        do {
            if contentParameters.count == 1 {
                requestJSONSchema = try componentsObjectBuilder.buildSchema(for: contentParameters[0].propertyType)
            } else if !contentParameters.isEmpty {
                requestJSONSchema = try componentsObjectBuilder.buildWrapperSchema(for: contentParameters.map {
                    $0.propertyType
                }, with: contentParameters.map {
                    $0.necessity
                })
            }
        } catch {
            fatalError("Could not build schema for request body wrapped by parameters \(contentParameters).")
        }
        if let requestJSONSchema = requestJSONSchema {
            requestBody = OpenAPI.Request(description: contentParameters
                .map {
                    $0.description
                }
                .joined(separator: "\n"),
                content: [
                    requestJSONSchema.openAPIContentType: .init(schema: requestJSONSchema)
                ]
            )
        }
        return requestBody
    }

    /// https://swagger.io/specification/#responses-object
    mutating func buildResponsesObject(from responseType: Encodable.Type) -> OpenAPI.Response.Map {
        var responseContent: OpenAPI.Content.Map = [:]
        let responseJSONSchema: JSONSchema
        do {
            responseJSONSchema = try componentsObjectBuilder.buildSchema(for: responseType)
        } catch {
            fatalError("Could not build schema for response body for type \(responseType).")
        }
        responseContent[responseJSONSchema.openAPIContentType] = .init(schema: responseJSONSchema)
        var responses: OpenAPI.Response.Map = [:]
        responses[.status(code: 200)] = .init(OpenAPI.Response(
            description: "OK",
            headers: nil,
            content: responseContent,
            vendorExtensions: [:])
        )
        responses[.status(code: 401)] = .init(
            OpenAPI.Response(description: "Unauthorized")
        )
        responses[.status(code: 403)] = .init(
            OpenAPI.Response(description: "Forbidden")
        )
        responses[.status(code: 404)] = .init(
            OpenAPI.Response(description: "Not Found")
        )
        responses[.status(code: 500)] = .init(
            OpenAPI.Response(description: "Internal Server Error")
        )
        return responses
    }
}
