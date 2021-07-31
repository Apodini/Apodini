//
//  LoggerParameterParsing.swift
//  
//
//  Created by Philipp Zagar on 10.06.21.
//
/*
import Foundation
import Vapor

protocol LoggerParameterParsing {
    func parseParameter(parameter: AnyEndpointParameter) throws -> String?
}

struct RESTLoggerParameterPrasing: LoggerParameterParsing {
    private let query: URLQueryContainer
    private let parameters: Parameters
    private let body: Vapor.Request.Body
    private let content: ContentContainer
    private let headers: HTTPHeaders
    
    init(query: URLQueryContainer,
         parameters: Parameters,
         body: Vapor.Request.Body,
         content: ContentContainer,
         headers: HTTPHeaders) {
        self.query = query
        self.parameters = parameters
        self.body = body
        self.content = content
        self.headers = headers
    }
    
    func parseParameter(parameter: AnyEndpointParameter) throws -> String? {
        parameter.propertyType
        switch parameter.parameterType {
        case .lightweight:

            guard let queryParameter = query[String.self, at: parameter.name] else {
                return nil // the query parameter doesn't exists
            }
            return queryParameter
        case .path:
            guard let stringParameter = parameters.get(parameter.pathId) else {
                return nil // the path parameter didn't exist on that request
            }

            return stringParameter
        case .content:
            guard body.data != nil else {
                return nil
            }
            let decodedData = try? content.decode(String.self, using: JSONDecoder())
            
            return decodedData
        }
    }
}
 */
