//
//  Created by Lorena Schlesinger on 15.11.20.
//

import OpenAPIKit

/// Corresponds to `paths` section in OpenAPI document
/// See: https://swagger.io/specification/#paths-object
class OpenAPIPathsObjectBuilder {

    func buildPathOperation(
            at endpoint: Endpoint,
            using openAPIComponentsBuilder: OpenAPIComponentsObjectBuilder) -> (OpenAPI.Operation, OpenAPI.HttpMethod) {
        let httpMethod = endpoint.operation.openAPIHttpMethod

        // create operation for pathItem + HTTP method
        // for now, we only use `responses`, `parameters`, and `requestBody`
        // as they are the only relevant fields for syntactic correctness of the spec
        // later on, we will add: `security: [OpenAPI.SecurityRequirement]`
        let parameters: OpenAPI.Parameter.Array = endpoint.parameters.compactMap {
            if let context = $0.openAPIContext {
                return Either.parameter(name: $0.name ?? $0.label, context: context, schema: $0.openAPISchema)
            }
            return nil
        }
        var requestBody: OpenAPI.Request? = nil
        let contentParameters = endpoint.parameters.filter {
            $0.parameterType == .content
        }
        var requestJSONSchema: JSONSchema? = nil
        if contentParameters.count == 1 {
            requestJSONSchema = try! openAPIComponentsBuilder.buildSchema(for: contentParameters[0].contentType)
        } else if !contentParameters.isEmpty {
            requestJSONSchema = try! openAPIComponentsBuilder.buildSchema(for: contentParameters.map {
                $0.contentType
            })
        }
        if let requestJSONSchema = requestJSONSchema {
            requestBody = OpenAPI.Request(content: [
                requestJSONSchema.openAPIContentType: .init(schema: requestJSONSchema)
            ])
        }
        var responseContent: OpenAPI.Content.Map = [:]
        let responseJSONSchema: JSONSchema = try! openAPIComponentsBuilder.buildSchema(for: endpoint.responseType)
        responseContent[responseJSONSchema.openAPIContentType] = .init(schema: responseJSONSchema)
        var responses: OpenAPI.Response.Map = [:]
        responses[OpenAPI.Response.StatusCode.status(code: 200)] = .init(OpenAPI.Response(
                description: "",
                headers: nil,
                content: responseContent,
                vendorExtensions: [:])
        )

        let security: [OpenAPI.SecurityRequirement]? = nil

        let op = OpenAPI.Operation(
                parameters: parameters,
                requestBody: requestBody,
                responses: responses,
                security: security)

        return (op, httpMethod)
    }
}
