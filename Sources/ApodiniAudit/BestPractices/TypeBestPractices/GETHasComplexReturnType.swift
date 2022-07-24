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

class GETHasComplexReturnType: BestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .httpMethod
    
    func check(into audit: Audit, _ app: Application) {
        // get operation for endpoint
        guard audit.endpoint[Operation.self] == Operation.read else {
            return
        }
        // If GET:
        // get return type of endpoint
        let returnType = audit.endpoint[ResponseType.self].type
        
        // Heuristic: report failure if
        // - Response Type is Status
        // - Response Type is Empty
        // - not implemented: stemmed Response type appears neither in Handler name nor endpoint path
        
        // Report failure if the return type is Status or Empty
        if returnType == Empty.self || returnType == Status.self {
            audit.recordFinding(GETReturnTypeFinding.getHasPrimitiveType)
        }
    }
    
    required init() { }
}


enum GETReturnTypeFinding: Finding {
    case getHasPrimitiveType
    
    var diagnosis: String {
        switch self {
        case .getHasPrimitiveType:
            return "No resource is returned from GET Handler"
        }
    }
}
