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
    
    func check(into report: AuditReport, _ app: Application) {
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
