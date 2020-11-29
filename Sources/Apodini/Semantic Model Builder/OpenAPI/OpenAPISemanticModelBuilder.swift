//
//  OpenAPISemanticModelBuilder.swift
//  
//
//  Created by Paul Schmiedmayer on 11/3/20.
//
import OpenAPIKit
import Vapor
import Foundation
import Runtime

class OpenAPISemanticModelBuilder: SemanticModelBuilder {
    var configuration: OpenAPIConfiguration
    var document: OpenAPI.Document
    var openAPIComponentsBuilder = OpenAPIComponentsBuilder()
    
    init(_ app: Application, configuration: OpenAPIConfiguration = OpenAPIConfiguration()) {
        self.configuration = configuration
        self.document = OpenAPI.Document(
            info: self.configuration.info,
            servers: self.configuration.servers,
            paths: OpenAPI.PathItem.Map(),
            components: self.openAPIComponentsBuilder.components
        )
        super.init(app)
        
        // TODO: add YAML and default case?
        // TODO: add file export?
        if let outputRoute = self.configuration.outputEndpoint {
            switch self.configuration.outputFormat {
            case .JSON:
                app.get(outputRoute.pathComponents) { (req: Vapor.Request) in
                    self.document
                }
            case .YAML:
                print("Not implemented yet.")
            default:
                print("Not implemented yet.")
            }
        }
    }
    
    override func register<C>(component: C, withContext context: Context) where C: Component {
        super.register(component: component, withContext: context)
        
        // add path item to `paths`
        do {
            try createOrUpdatePathItem(of: component, withContext: context)
        } catch HTTPMethod.OpenAPIHTTPMethodError.unsupportedHttpMethod {
            app.logger.error("Error occurred when mapping Vapor HTTP method to OpenAPI HTTP method.")
        } catch {
            app.logger.error("Some unknown error occurred: \(error).")
        }
        
    }
    
    
    private func createOrUpdatePathItem<C>(of component: C, withContext context: Context) throws -> Void where C: Component {
        print("\(C.Response.self)")
        // get path from `PathComponent`s
        let pathComponents = context.get(valueFor: PathComponentContextKey.self)
        let pathBuilder = OpenAPIPathBuilder(pathComponents)
        let path = OpenAPI.Path(stringLiteral: pathBuilder.fullPath)
        
        // find or create pathItem
        var pathItem = self.document.paths[path] ?? OpenAPI.PathItem()
        
        // get HTTP method
        let httpMethod = try context.get(valueFor: HTTPMethodContextKey.self).openAPIHttpMethod()
        
        // 1. get (ultimate) response type from transformers
        let responseTransformerTypes = context.get(valueFor: ResponseContextKey.self)
        let returnType: ResponseEncodable.Type = {
            guard let lastResponseTransformerType = responseTransformerTypes.last else {
                return C.Response.self
            }
            return lastResponseTransformerType().transformedResponseType
        }()
        
        // get guards -> TODO: add as security fields?
        let guards = context.get(valueFor: GuardContextKey.self)
        
        // create operation for pathItem + HTTP method
        // for now, we only use `responses`, `parameters`, and `requestBody`
        // as they are the only relevant fields for syntactic correctness of the spec
        // later on, we will add: `security: [OpenAPI.SecurityRequirement]`
        let parameters = pathBuilder.parameters.compactMap {
            Either.parameter(name: $0, context: .path, schema: .string)
        } // TODO: here we need to add `QueryParams`
        let requestBody: OpenAPI.Request = OpenAPI.Request(content: OpenAPI.Content.Map())
        var responseContent: OpenAPI.Content.Map = [:]
        var responseJSONSchema: JSONSchema = try! self.openAPIComponentsBuilder.findOrCreateSchema(from: returnType)
        responseContent[.json] = .init(schema: responseJSONSchema)
        var responses: OpenAPI.Response.Map = [:]
        responses[OpenAPI.Response.StatusCode.range(.success)] = .init(OpenAPI.Response.init(
            description: "",
            headers: nil,
            content: responseContent,
            vendorExtensions: [:])
        )
        
        let security: [OpenAPI.SecurityRequirement] = []
        
        let operation = OpenAPI.Operation(
            parameters: parameters,
            requestBody: requestBody,
            responses: responses,
            security: security)
    
        pathItem.set(operation: operation, for: httpMethod)
        
        self.document.paths[path] = pathItem
        self.document.components = self.openAPIComponentsBuilder.components
        
        let encoder = JSONEncoder()
        if let json = try? encoder.encode(self.document) {
            print(String(data: json, encoding: .utf8)!)
        }
    }
    
}
