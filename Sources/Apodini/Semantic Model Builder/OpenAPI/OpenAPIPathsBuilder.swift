//
//  OpenAPIPathsBuilder.swift
//  
//
//  Created by Lorena Schlesinger on 15.11.20.
//

import OpenAPIKit

/// Corresponds to `paths` section in OpenAPI document
/// See: https://swagger.io/specification/#paths-object
class OpenAPIPathsBuilder {

    func buildPathOperation(
            at endpoint: Endpoint,
            with operation: Operation,
            using openAPIComponentsBuilder: OpenAPIComponentsBuilder) -> (OpenAPI.Operation, OpenAPI.HttpMethod) {
        var endpoint = endpoint
        let httpMethod = endpoint.operation.openAPIHttpMethod()

        // create operation for pathItem + HTTP method
        // for now, we only use `responses`, `parameters`, and `requestBody`
        // as they are the only relevant fields for syntactic correctness of the spec
        // later on, we will add: `security: [OpenAPI.SecurityRequirement]`
        let parameters: OpenAPI.Parameter.Array = endpoint.parameters.compactMap {
            if let context = $0.openAPIContext() {
                return Either.parameter(name: $0.name ?? $0.label, context: context, schema: $0.openAPISchema())
            }
            return nil
        }


        // TODO: extract from parameter with type .content
        let requestBody: OpenAPI.Request = OpenAPI.Request(content: OpenAPI.Content.Map())
        var responseContent: OpenAPI.Content.Map = [:]
        let responseJSONSchema: JSONSchema = try! openAPIComponentsBuilder.buildSchema(for: endpoint.responseType)
        responseContent[.json] = .init(schema: responseJSONSchema)
        var responses: OpenAPI.Response.Map = [:]
        responses[OpenAPI.Response.StatusCode.status(code: 200)] = .init(OpenAPI.Response(
                description: "",
                headers: nil,
                content: responseContent,
                vendorExtensions: [:])
        )

        let security: [OpenAPI.SecurityRequirement] = []

        let op = OpenAPI.Operation(
                parameters: parameters,
                requestBody: requestBody,
                responses: responses,
                security: security)

        return (op, httpMethod)
    }
}
