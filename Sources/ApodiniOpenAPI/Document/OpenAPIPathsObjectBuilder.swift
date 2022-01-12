//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import ApodiniOpenAPISecurity
import OpenAPIKit
import ApodiniREST


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
    let rootPath: Apodini.EndpointPath?
    
    init(componentsObjectBuilder: OpenAPIComponentsObjectBuilder, rootPath: EndpointPath?) {
        self.componentsObjectBuilder = componentsObjectBuilder
        self.rootPath = rootPath
    }
    
    /// https://swagger.io/specification/#path-item-object
    mutating func addPathItem<H: Handler>(from endpoint: Endpoint<H>) {
        // Get OpenAPI-compliant path representation.
        let absolutePath = endpoint.absoluteRESTPath(rootPrefix: rootPath)
        
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
        let handlerContext = endpoint[Context.self]

        var defaultTag: String
        let absolutePath = endpoint.absoluteRESTPath(rootPrefix: rootPath)
        
        // If parameter in path, get string component directly before first parameter component in path.
        if let index = absolutePath.firstIndex(where: { $0.isParameter() }), index > 0 {
            let stringComponent = absolutePath[index - 1].description
            defaultTag = stringComponent.isEmpty ? "default" : stringComponent
            // If not, get string component that was appended last to the path.
        } else {
            defaultTag = absolutePath.last { ($0.isString()) }?.description ?? "default"
        }
        
        // Get tags if some have been set explicitly passed via TagModifier.
        let tags: [String] = handlerContext.get(valueFor: TagContextKey.self) ?? [defaultTag]
        
        // Get customDescription if it has been set explicitly passed via DescriptionModifier.
        let customDescription = handlerContext.get(valueFor: HandlerDescriptionMetadata.self)

        // Set endpointDescription to customDescription or `endpoint.description` holding the `Handler`s type name.
        let endpointDescription = customDescription ?? endpoint.description

        // Get `Parameter.Array` from existing `query` or `path` parameters.
        let parameters: OpenAPIKit.OpenAPI.Parameter.Array = buildParametersArray(from: endpoint.parameters, with: handlerContext)
        // Get `OpenAPI.Request` body object containing HTTP body types.
        let requestBody: OpenAPIKit.OpenAPI.Request? = buildRequestBodyObject(from: endpoint.parameters)
        
        // Get `OpenAPI.Response.Map` containing all possible HTTP responses mapped to their status code.
        let responses: OpenAPIKit.OpenAPI.Response.Map = buildResponsesObject(from: endpoint[ResponseType.self].type)

        let securitySchemes = handlerContext
            .get(valueFor: SecurityMetadata.self)
            .map(to: EndpointSecurityDescription.self, on: endpoint)

        var securityArray: [OpenAPIKit.OpenAPI.SecurityRequirement] = []
        var requiredSecurityRequirementIndex: Int?

        var requiresAuthentication = false

        // see https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#security-requirement-object
        // all required security is placed in the **same** `SecurityRequirement` object
        // the list of `SecurityRequirement` it encodes that only one of those is required.

        for (key, description) in securitySchemes {
            guard let componentKey = OpenAPIKit.OpenAPI.ComponentKey(rawValue: key) else {
                fatalError("""
                           Security Metadata Key must match pattern '^[a-zA-Z0-9\\.\\-_]+$'. \
                           Key '\(key)' for \(description) didn't match.
                           """)
            }

            componentsObjectBuilder.addSecurityScheme(key: componentKey, scheme: description.scheme)

            requiresAuthentication = requiresAuthentication || description.required

            if !description.required {
                securityArray.append([.component(named: componentKey.rawValue): description.scopes])
                continue
            }

            if let requiredIndex = requiredSecurityRequirementIndex {
                securityArray[requiredIndex][.component(named: componentKey.rawValue)] = description.scopes
            } else {
                requiredSecurityRequirementIndex = securityArray.count
                securityArray.append([.component(named: componentKey.rawValue): description.scopes])
            }
        }

        if !securityArray.isEmpty && !requiresAuthentication {
            // OpenAPI represents optional authentication with an empty SecurityRequirement
            // see https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md#security-requirement-object
            securityArray.append([:])
        }

        return OpenAPIKit.OpenAPI.Operation(
            tags: tags,
            summary: handlerContext.get(valueFor: HandlerSummaryMetadata.self),
            description: endpointDescription,
            operationId: endpoint[AnyHandlerIdentifier.self].rawValue,
            parameters: parameters,
            requestBody: requestBody,
            responses: responses,
            security: securityArray.isEmpty ? nil : securityArray,
            vendorExtensions: [
                "x-apodiniHandlerId": AnyCodable(endpoint[AnyHandlerIdentifier.self].rawValue),
                "x-apodiniHandlerCommunicationalPattern": AnyCodable(endpoint[CommunicationalPattern.self].rawValue)
            ]
        )
    }
    
    /// https://swagger.io/specification/#parameter-object
    mutating func buildParametersArray(from parameters: [AnyEndpointParameter], with handlerContext: Context) -> OpenAPIKit.OpenAPI.Parameter.Array {
        let parameterDescription = handlerContext.get(valueFor: ParameterDescriptionContextKey.self)

        return parameters.compactMap {
            guard let context = OpenAPIKit.OpenAPI.Parameter.Context($0) else {
                return nil // filter out content parameters
            }

            return Either.parameter(
                name: $0.name,
                context: context,
                schema: .from($0.propertyType),
                description: parameterDescription[$0.id] ?? $0.description
            )
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
            fatalError("Could not build schema for response body for type \(responseType): \(error)")
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
