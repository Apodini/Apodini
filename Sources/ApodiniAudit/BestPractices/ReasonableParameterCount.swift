//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

struct ReasonableParameterCount: BestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .parameters
    
    var configuration = ReasonableParameterCountConfiguration()
    
    func check(into audit: Audit, _ app: Application) {
        let parameters = audit.endpoint.parameters
        
        /// We consider `lightweight` and `path` parameters here
        let nonContentParams = parameters.filter {
            $0.parameterType != .content
        }
        let paramCount = nonContentParams.count
        
        if paramCount > configuration.maximumCount {
            audit.recordFinding(ParameterCountFinding.tooManyParameters(count: paramCount))
        }
    }
}

enum ParameterCountFinding: Finding {
    case tooManyParameters(count: Int)
    
    var diagnosis: String {
        switch self {
        case .tooManyParameters(let count):
            return "This Endpoint has too many parameters: \(count)"
        }
    }
}

struct ReasonableParameterCountConfiguration: BestPracticeConfiguration {
    var maximumCount = 10
    
    func configure() -> BestPractice {
        ReasonableParameterCount(configuration: self)
    }
}
