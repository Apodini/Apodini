//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import ApodiniTypeInformation
import ApodiniNetworking

/// BP23 & BP73
/// Ensures that GET, PUT, and DELETE Handlers have complex return types,
/// as opposed to performing e.g. a database transaction and not returning a resource.
public class EndpointHasComplexReturnType: BestPractice {
    public static var scope: BestPracticeScopes = .rest
    public static var category: BestPracticeCategories = .httpMethod
    
    private var checkedHandlerNames = [String]()
    
    public func check(into audit: Audit, _ app: Application) {
        // Check cache and add to cache if it's a cache miss
        let handlerName = audit.endpoint[HandlerReflectiveName.self].rawValue
        guard !checkedHandlerNames.contains(handlerName) else {
            return
        }
        checkedHandlerNames.append(handlerName)
        
        // Check for all operations except .create, which is POST for HTTP
        let operation = audit.endpoint[Operation.self]
        guard operation != Operation.create else {
            return
        }
        
        // get return type of endpoint
        // This is the unwrapped return type, NOT something like EventLoopFuture<String> etc.
        let returnType = audit.endpoint[ResponseType.self].type
        
        // Heuristic: report failure if
        // - Response Type is Status
        // - Response Type is Empty
        
        // Report failure if the return type is Status or Empty
        if returnType == Empty.self || returnType == Status.self {
            audit.recordFinding(ReturnTypeFinding.hasPrimitiveReturnType(operation))
        }
    }
    
    public required init() { }
}


enum ReturnTypeFinding: Finding, Equatable {
    case hasPrimitiveReturnType(Apodini.Operation)
    
    var diagnosis: String {
        switch self {
        case .hasPrimitiveReturnType(let operation):
            return "No resource is returned from \(HTTPMethod(operation).rawValue) Handler"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .hasPrimitiveReturnType(let operation):
            return "Consider using Apodini's standard \(operation.rawValue) handler!"
        }
    }
}
