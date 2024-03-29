//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

/// BP19
/// Checks that Handlers don't have too many parameters. If a Handler has lots of parameters, this suggests that it acts like a "God Component",
/// and might better be split up into multiple smaller Handlers.
public class ReasonableParameterCount: BestPractice {
    public required init() { }
    
    public static var scope: BestPracticeScopes = .rest
    public static var category: BestPracticeCategories = .parameters
    
    var configuration = ParameterCountConfiguration()
    
    private var checkedHandlerNames = [String]()
    
    public func check(into audit: Audit, _ app: Application) {
        let handlerName = audit.endpoint[HandlerReflectiveName.self].rawValue
        guard !checkedHandlerNames.contains(handlerName) else {
            return
        }
        
        checkedHandlerNames.append(handlerName)
        
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
    
    public init(configuration: ParameterCountConfiguration) {
        self.configuration = configuration
    }
}

enum ParameterCountFinding: Finding, Equatable {
    case tooManyParameters(count: Int)
    
    var diagnosis: String {
        switch self {
        case .tooManyParameters(let count):
            return "This handler has too many parameters: \(count)"
        }
    }
}

public struct ParameterCountConfiguration: BestPracticeConfiguration {
    var maximumCount: Int
    
    public func configure() -> BestPractice {
        ReasonableParameterCount(configuration: self)
    }
    
    public init(maximumCount: Int = 10) {
        self.maximumCount = maximumCount
    }
}
