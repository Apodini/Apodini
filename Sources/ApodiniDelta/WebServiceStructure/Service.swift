//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Foundation

struct Service: Codable {

    let handlerName: String
    let handlerIdentifier: AnyHandlerIdentifier
    let operation: Apodini.Operation
    let absolutePath: String
    let parameters: [ServiceParameter]
    let response: SchemaReference

    init(
        handlerName: String,
        handlerIdentifier: AnyHandlerIdentifier,
        operation: Apodini.Operation,
        absolutePath: [EndpointPath],
        parameters: [ServiceParameter],
        response: SchemaReference
    ) {
        self.handlerName = handlerName
        self.handlerIdentifier = handlerIdentifier
        self.operation = operation
        self.absolutePath = absolutePath.asPathString()
        self.parameters = parameters
        self.response = response
    }
}
