//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

protocol URLSegmentBestPractice: BestPractice {
    static var successMessage: String { get }
    
    static func checkSegment(segment: String) -> String?
}

extension URLSegmentBestPractice {
    var scope: BestPracticeScope = .all
    
    static func check(_ app: Application, _ endpoint: AnyEndpoint) -> AuditReport {
        for segment in endpoint.absolutePath {
            if case .string(let identifier) = segment,
                let failMessage = checkSegment(segment: identifier) {
                return AuditReport(message: failMessage, auditResult: .fail)
            }
        }
        return AuditReport(message: successMessage, auditResult: .success)
    }
}

struct AppropriateLengthForURLPathSegments: URLSegmentBestPractice {
    static var category = BestPracticeCategory.urlPath
    static var successMessage = "The path segments have appropriate lengths"
    
    static let minimumLength = 3
    static let maximumLength = 30
    
    static func checkSegment(segment: String) -> String? {
        if segment.count < minimumLength || segment.count > maximumLength {
            return "The path segment \"\(segment)\" is too short or too long"
        }
        return nil
    }
}

struct NoUnderscoresInURLPathSegments: URLSegmentBestPractice {
    static var category = BestPracticeCategory.urlPath
    static var successMessage = "The path segments do not contain any underscores"
    
    static func checkSegment(segment: String) -> String? {
        if segment.contains("_") {
            return "The path segment \(segment) contains one or more underscores"
        }
        return nil
    }
}
