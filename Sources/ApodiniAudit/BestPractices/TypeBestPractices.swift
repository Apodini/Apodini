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

struct GETHasComplexReturnType: BestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .method
    
    func check(into audit: Audit, _ app: Application) {
        // get operation for endpoint
        guard audit.endpoint[Operation.self] == Operation.read else {
            return
        }
        // If GET:
        // get return type of endpoint
        let returnType = audit.endpoint[ResponseType.self].type
        
        guard let responseTypeInformation = TypeInformation.buildOptional(returnType) else {
            return
        }
        
        // Report failure if the return type is primitive
        if !responseTypeInformation.isObject && !responseTypeInformation.isDictionary && !responseTypeInformation.isRepeated {
            audit.recordFinding("The GET handler does not return a complex type", .fail)
        }
        
        // TODO do something special for `Response` types?
    }
}
