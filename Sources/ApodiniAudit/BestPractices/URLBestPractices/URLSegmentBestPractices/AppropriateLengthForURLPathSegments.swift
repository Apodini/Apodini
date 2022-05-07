//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

struct AppropriateLengthForURLPathSegments: URLSegmentBestPractice {
    var scope: BestPracticeScopes = .all
    var category: BestPracticeCategories = .urlPath
    var successMessage = "The path segments have appropriate lengths"
    
    var configuration = AppropriateLengthForURLPathSegmentsConfiguration()
    
    func checkSegment(segment: String) -> String? {
        if segment.count < configuration.minimumLength || segment.count > configuration.maximumLength {
            return "The path segment \"\(segment)\" is too short or too long"
        }
        return nil
    }
}

struct AppropriateLengthForURLPathSegmentsConfiguration: BestPracticeConfiguration {
    var minimumLength = 3
    var maximumLength = 30
    
    func configureBestPractice() -> BestPractice {
        AppropriateLengthForURLPathSegments(configuration: self)
    }
}
