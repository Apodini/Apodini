//
//  OpenAPISemanticModelBuilder.swift
//  
//
//  Created by Paul Schmiedmayer on 11/3/20.
//
import OpenAPIKit
import Vapor
import Foundation

class OpenAPISemanticModelBuilder: SemanticModelBuilder {
    var configuration: OpenAPIConfiguration
    var document: OpenAPI.Document
    
    init(_ app: Application, configuration: OpenAPIConfiguration = OpenAPIConfiguration()) {
        self.configuration = configuration
        self.document = OpenAPI.Document(
            info: self.configuration.info,
            servers: self.configuration.servers,
            paths: OpenAPI.PathItem.Map(),
            components: OpenAPI.Components()
        )
        super.init(app)
        
        // TODO: should we create a vapor endpoint (if defined in configuration) here?
        // if yes, define request handler which returns representation of
        // `self.document` (or &self.document)
        
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
        
        // if new schema detected, add to components
        
        // 
        //#if DEBUG
        //self.printRESTPath(of: component, withContext: context)
        //#endif

    }
    
    
    private func createOrUpdatePathItem<C>(of component: C, withContext context: Context) throws -> Void where C: Component {
        
        // get path from `PathComponent`s
        let pathComponents = context.get(valueFor: PathComponentContextKey.self)
        let pathBuilder = OpenAPIPathBuilder(pathComponents)
        let path = OpenAPI.Path(stringLiteral: pathBuilder.fullPath)
        
        // find or create pathItem
        var pathItem = self.document.paths[path] ?? OpenAPI.PathItem()
        
        // get HTTP method
        let httpMethod = try context.get(valueFor: HTTPMethodContextKey.self).openAPIHttpMethod()
        
        // get (ultimate) response type from transformers
        let responseTransformerTypes = context.get(valueFor: ResponseContextKey.self)
        let returnType: ResponseEncodable.Type = {
            if responseTransformerTypes.isEmpty {
                return C.Response.self
            } else {
                return responseTransformerTypes.last!().transformedResponseType
            }
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
        let responses: OpenAPI.Response.Map = OpenAPI.Response.Map()
        let security: [OpenAPI.SecurityRequirement] = []
        
        let operation = OpenAPI.Operation(
            parameters: parameters,
            requestBody: requestBody,
            responses: responses,
            security: security)
    
        pathItem.set(operation: operation, for: httpMethod)
        
        self.document.paths[path] = pathItem
        
        let encoder = JSONEncoder()
        if let json = try? encoder.encode(self.document) {
            print(String(data: json, encoding: .utf8)!)
        }
    }
    
}
