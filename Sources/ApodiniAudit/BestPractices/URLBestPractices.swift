//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
