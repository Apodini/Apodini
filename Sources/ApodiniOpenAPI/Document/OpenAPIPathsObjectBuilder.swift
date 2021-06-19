//
//  Created by Lorena Schlesinger on 15.11.20.
//

import Apodini
import OpenAPIKit


/// Utility to convert `_PathComponent`s to `OpenAPI.Path` format.
struct OpenAPIPathBuilder: PathBuilderWithResult {
    var components: [String] = []
    
    mutating func append(_ string: String) {
        components.append(string)
    }
    
    mutating func append<Type: Codable>(_ parameter: EndpointPathParameter<Type>) {
        components.append("{\(parameter.name)}")
    }
    
    func result() -> OpenAPIKit.OpenAPI.Path {
        OpenAPIKit.OpenAPI.Path(stringLiteral: self.components.joined(separator: "/"))
    }
}

/// Corresponds to `paths` section in OpenAPI document.
/// See: https://swagger.io/specification/#paths-object
struct OpenAPIPathsObjectBuilder {
    var pathsObject: OpenAPIKit.OpenAPI.PathItem.Map = [:]
    let componentsObjectBuilder: OpenAPIComponentsObjectBuilder
    
    init(componentsObjectBuilder: inout OpenAPIComponentsObjectBuilder) {
        self.componentsObjectBuilder = componentsObjectBuilder
    }
    
    /// https://swagger.io/specification/#path-item-object
    mutating func addPathItem<H: Handler>(from endpoint: Endpoint<H>) {
        // Get OpenAPI-compliant path representation.
        let absolutePath = endpoint.absoluteRESTPath
        
        let path = absolutePath.build(with: OpenAPIPathBuilder.self)

        // Get or create `PathItem`.
        var pathItem = pathsObject[path] ?? OpenAPIKit.OpenAPI.PathItem()
        
        // Get `OpenAPI.HttpMethod` and `OpenAPI.Operation` from endpoint.
        let httpMethod = OpenAPIKit.OpenAPI.HttpMethod(endpoint[Operation.self])
        let operation = buildPathItemOperationObject(from: endpoint)
        pathItem.set(operation: operation, for: httpMethod)
        
        // Add (or override) `PathItem` to map of paths.
        pathsObject[path] = pathItem
    }
}

private extension OpenAPIPathsObjectBuilder {
    /// https://swagger.io/specification/#operation-object
    mutating func buildPathItemOperationObject<H: Handler>(from endpoint: Endpoint<H>) -> OpenAPIKit.OpenAPI.Operation {
        var defaultTag: String
        let absolutePath = endpoint.absoluteRESTPath
        
        // If parameter in path, get string component directly before first parameter component in path.
        if let index = absolutePath.firstIndex(where: { $0.isParameter() }), index > 0 {
            let stringComponent = absolutePath[index - 1].description
            defaultTag = stringComponent.isEmpty ? "default" : stringComponent
            // If not, get string component that was appended last to the path.
        } else {
            defaultTag = absolutePath.last { ($0.isString()) }?.description ?? "default"
        }
        
        // Get tags if some have been set explicitly passed via TagModifier.
        let tags: [String] = endpoint[Context.self].get(valueFor: TagContextKey.self) ?? [defaultTag]
        
        // Get customDescription if it has been set explicitly passed via DescriptionModifier.
        let customDescription = endpoint[Context.self].get(valueFor: DescriptionContextKey.self)
        
        // Set endpointDescription to customDescription or `endpoint.description` holding the `Handler`s type name.
        let endpointDescription = customDescription ?? endpoint.description
        
        // Get `Parameter.Array` from existing `query` or `path` parameters.
        let parameters: OpenAPIKit.OpenAPI.Parameter.Array = buildParametersArray(from: endpoint.parameters)
        
        // Get `OpenAPI.Request` body object containing HTTP body types.
        let requestBody: OpenAPIKit.OpenAPI.Request? = buildRequestBodyObject(from: endpoint.parameters)
        
        // Get `OpenAPI.Response.Map` containing all possible HTTP responses mapped to their status code.
        let responses: OpenAPIKit.OpenAPI.Response.Map = buildResponsesObject(from: endpoint[ResponseType.self].type)
        
        return OpenAPIKit.OpenAPI.Operation(
            tags: tags,
            description: endpointDescription,
            operationId: endpoint[AnyHandlerIdentifier.self].rawValue,
            parameters: parameters,
            requestBody: requestBody,
            responses: responses,
            vendorExtensions: [
                "x-apodiniHandlerId": AnyCodable(endpoint[AnyHandlerIdentifier.self].rawValue)
            ]
        )
    }
    
    /// https://swagger.io/specification/#parameter-object
    mutating func buildParametersArray(from parameters: [AnyEndpointParameter]) -> OpenAPIKit.OpenAPI.Parameter.Array {
        parameters.compactMap {
            if let context = OpenAPIKit.OpenAPI.Parameter.Context($0) {
                return Either.parameter(name: $0.name, context: context, schema: JSONSchema.from($0.propertyType), description: $0.description)
            }
            return nil
        }
    }
    
    /// https://swagger.io/specification/#request-body-object
    mutating func buildRequestBodyObject(from parameters: [AnyEndpointParameter]) -> OpenAPIKit.OpenAPI.Request? {
        var requestBody: OpenAPIKit.OpenAPI.Request?
        let contentParameters = parameters.filter {
            $0.parameterType == .content
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
            requestBody = OpenAPIKit.OpenAPI.Request(description: contentParameters
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
    mutating func buildResponsesObject(from responseType: Encodable.Type) -> OpenAPIKit.OpenAPI.Response.Map {
        var responseContent: OpenAPIKit.OpenAPI.Content.Map = [:]
        let responseJSONSchema: JSONSchema
        do {
            responseJSONSchema = try componentsObjectBuilder.buildResponse(for: responseType)
        } catch {
            fatalError("Could not build schema for response body for type \(responseType).")
        }
        responseContent[responseJSONSchema.openAPIContentType] = .init(schema: responseJSONSchema)
        var responses: OpenAPIKit.OpenAPI.Response.Map = [:]
        responses[.status(code: 200)] = .init(OpenAPIKit.OpenAPI.Response(
                                                description: "OK",
                                                headers: nil,
                                                content: responseContent,
                                                vendorExtensions: [:])
        )
        responses[.status(code: 401)] = .init(
            OpenAPIKit.OpenAPI.Response(description: "Unauthorized")
        )
        responses[.status(code: 403)] = .init(
            OpenAPIKit.OpenAPI.Response(description: "Forbidden")
        )
        responses[.status(code: 404)] = .init(
            OpenAPIKit.OpenAPI.Response(description: "Not Found")
        )
        responses[.status(code: 500)] = .init(
            OpenAPIKit.OpenAPI.Response(description: "Internal Server Error")
        )
        return responses
    }
}

extension AnyEndpoint {
    /// RESTInterfaceExporter exports `@Parameter(.http(.path))`, which are not listed on the
    /// path-elements on the `Component`-tree as additional path elements at the end of the path.
    var absoluteRESTPath: [EndpointPath] {
        self[EndpointPathComponentsHTTP.self].value
    }
}
