//
//  File.swift
//  
//
//  Created by Simon Bohnen on 3/21/22.
//

import Foundation
import Apodini

struct AppropriateLengthForURLPathSegments: BestPractice {
    static var category = BestPracticeCategory.urlPath
    
    static let minimumLength = 3
    static let maximumLength = 30
    
    static func check(_ app: Application, _ endpoint: AnyEndpoint) -> AuditReport {
        // Go through all the path segments
        for segment in endpoint.absolutePath {
            if case .string(let identifier) = segment {
                if identifier.count < minimumLength || identifier.count > maximumLength {
                    return AuditReport(message: "The path segment \"\(identifier)\" is too short or too long", auditResult: .fail)
                }
            }
        }
        
        return AuditReport(message: "The path segments have appropriate lengths", auditResult: .success)
    }
}
