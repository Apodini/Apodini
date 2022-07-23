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
    
    func check(into audit: Audit, _ app: Application) {
        let pathSegments = audit.endpoint.absolutePath
        let firstStringSegment = pathSegments.first { path in
            if case .string( _) = path {
                return true
            }
            return false
        }
        guard let firstStringSegment = firstStringSegment,
              case .string(let firstString) = firstStringSegment,
              let firstStringIndex = pathSegments.firstIndex(of: firstStringSegment) else {
            // We have nothing to check here
            return
        }

        var latestString = firstString
        for segmentIndex in firstStringIndex + 1..<pathSegments.count {
            if case .string(let nextString) = pathSegments[segmentIndex] {
                if NLTKInterface.shared.synsetIntersectionEmpty(latestString, nextString) {
                    audit.recordFinding(ContextualisedResourceNamesFinding.unrelatedSegments(segment1: latestString, segment2: nextString))
                }
                latestString = nextString
            }
        }
    }
}

enum ContextualisedResourceNamesFinding: Finding {
    case unrelatedSegments(segment1: String, segment2: String)
    
    var diagnosis: String {
        switch self {
        case .unrelatedSegments(let segment1, let segment2):
            return "\"\(segment1)\" and \"\(segment2)\" are not related!"
        }
    }
}