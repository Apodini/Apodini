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

class DELETEHasComplexReturnType: BestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .httpMethod
    
    private var checkedHandlerNames = [String]()
    
    func check(into audit: Audit, _ app: Application) {
        let handlerName = audit.endpoint[HandlerReflectiveName.self].rawValue
        guard !checkedHandlerNames.contains(handlerName) else {
            return
        }
        
        checkedHandlerNames.append(handlerName)
        
        // get operation for endpoint
        guard audit.endpoint[Operation.self] == Operation.delete else {
            return
        }
        // If DELETE:
        // get return type of endpoint
        let returnType = audit.endpoint[ResponseType.self].type
        
        // Heuristic: report failure if
        // - Response Type is Status
        // - Response Type is Empty
        // - not implemented: stemmed Response type appears neither in Handler name nor endpoint path
        
        // Report failure if the return type is Status or Empty
        if returnType == Empty.self || returnType == Status.self {
            audit.recordFinding(DELETEReturnTypeFinding.deleteHasPrimitiveType)
        }
    }
    
    required init() { }
}


enum DELETEReturnTypeFinding: Finding {
    case deleteHasPrimitiveType
    
    var diagnosis: String {
        switch self {
        case .deleteHasPrimitiveType:
            return "The deleted resource is not returned"
        }
    }
    
    var suggestion: String? {
        switch self {
        case .deleteHasPrimitiveType:
            return "Consider using Apodini's standard Delete handler!"
        }
    }
}
