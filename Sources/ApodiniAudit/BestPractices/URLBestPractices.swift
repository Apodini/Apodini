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
    
    static func check(into report: AuditReport, _ app: Application) {
        let pathSegments = report.endpoint.absolutePath
        let firstStringSegment = pathSegments.first { path in
            if case .string( _) = path {
                return true
            }
            return false
        }
        guard let firstStringSegment = firstStringSegment,
              case .string(let firstString) = firstStringSegment,
              let firstStringIndex = pathSegments.firstIndex(of: firstStringSegment) else {
            report.recordFinding("Nothing to check for endpoint \(report.endpoint)", .success)
            return
        }

        var latestString = firstString
        for segmentIndex in firstStringIndex + 1..<pathSegments.count {
            if case .string(let nextString) = pathSegments[segmentIndex] {
                if NLTKInterface.shared.synsetIntersectionEmpty(latestString, nextString) {
                    report.recordFinding("\"\(latestString)\" and \"\(nextString)\" are not related!", .fail)
                }
                print("\"\(latestString)\" and \"\(nextString)\" are related!")
                latestString = nextString
            }
        }
    }
}

protocol URLSegmentBestPractice: BestPractice {
    static var successMessage: String { get }
    
    static func checkSegment(segment: String) -> String?
}

extension URLSegmentBestPractice {
    static func check(into report: AuditReport, _ app: Application) {
        for segment in report.endpoint.absolutePath {
            if case .string(let identifier) = segment,
                let failMessage = checkSegment(segment: identifier) {
                report.recordFinding(failMessage, .fail)
            }
        }
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
    private static var crudVerbs = ["get", "post", "remove", "delete", "put"]
    
    static func checkSegment(segment: String) -> String? {
        let containsCRUDVerb = crudVerbs.contains { segment.lowercased().contains($0) }
        if containsCRUDVerb {
            return "The path segment \(segment) contains one or more CRUD verbs!"
        }
        return nil
    }
}

struct LowercaseURLPathSegments: URLSegmentBestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .urlPath
    static var successMessage = "The path segments do not contain any uppercase letters"
    
    static func checkSegment(segment: String) -> String? {
        if segment.lowercased() != segment {
            return "The path segment \(segment) contains one or more uppercase letters!"
        }
        return nil
    }
}

struct NoFileExtensionsInURLPathSegments: URLSegmentBestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .urlPath
    static var successMessage = "The path segments do not contain any uppercase letters"
    static var allowedExtensions: [String] = []
    /// The minimum distance from the end of the segment that a dot has to have
    /// in order to not be recognized as a file extension.
    /// If this is 4, then 'html' would not be recognized as a file extension
    static var minDistanceFromEnd = 5
    
    static func checkSegment(segment: String) -> String? {
        let dotIndex = segment.firstIndex(of: ".")
        guard let dotIndex = dotIndex else {
            return nil
        }
        let dotIndexInt = segment.distance(from: segment.startIndex, to: dotIndex)
        let extensionLength = segment.count - dotIndexInt - 1
        if extensionLength >= minDistanceFromEnd ||
            allowedExtensions.contains(String(segment.suffix(extensionLength))) {
            return nil
        }
        return "The path segment \(segment) has a file extension."
    }
}
