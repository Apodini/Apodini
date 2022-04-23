//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini

struct ContextualisedResourceNames: BestPractice {
    static var scope: BestPracticeScopes = .all
    static var category: BestPracticeCategories = .urlPath
    
    static func check(_ app: Application, _ endpoint: AnyEndpoint) -> AuditReport {
        let pathSegments = endpoint.absolutePath
        let firstStringSegment = pathSegments.first { path in
            if case .string( _) = path {
                return true
            }
            return false
        }
        guard let firstStringSegment = firstStringSegment,
              case .string(let firstString) = firstStringSegment,
              let firstStringIndex = pathSegments.firstIndex(of: firstStringSegment) else {
            return AuditReport(message: "Nothing to check for endpoint \(endpoint)", auditResult: .success)
        }

        var latestString = firstString
        for segmentIndex in firstStringIndex + 1..<pathSegments.count {
            if case .string(let nextString) = pathSegments[segmentIndex] {
                if NLTKInterface.shared.synsetIntersectionEmpty(latestString, nextString) {
                    return AuditReport(message: "\"\(latestString)\" and \"\(nextString)\" are not related!", auditResult: .fail)
                }
                print("\"\(latestString)\" and \"\(nextString)\" are related!")
                latestString = nextString
            }
        }
        return AuditReport(message: "All segments are related!", auditResult: .success)
    }
}

protocol URLSegmentBestPractice: BestPractice {
    static var successMessage: String { get }
    
    static func checkSegment(segment: String) -> String?
}

extension URLSegmentBestPractice {
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
    static var scope: BestPracticeScopes = .all
    static var category: BestPracticeCategories = .urlPath
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
    static var scope: BestPracticeScopes = .all
    static var category: BestPracticeCategories = .urlPath
    static var successMessage = "The path segments do not contain any underscores"
    
    static func checkSegment(segment: String) -> String? {
        if segment.contains("_") {
            return "The path segment \(segment) contains one or more underscores"
        }
        return nil
    }
}

struct NoCRUDVerbsInURLPathSegments: URLSegmentBestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .urlPath
    static var successMessage = "The path segments do not contain any CRUD verbs"
    static var crudVerbs = ["get", "post", "remove", "delete", "put"]
    
    static func checkSegment(segment: String) -> String? {
        if crudVerbs.contains { segment.lowercased().contains($0) } {
            return "The path segment \(segment) contains one or more CRUD verbs!"
        }
        return nil
    }
}
