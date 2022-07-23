//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

struct AppropriateLengthForURLPathSegments: URLSegmentBestPractice {
    static var scope: BestPracticeScopes = .all
    static var category: BestPracticeCategories = .urlPath
    var successMessage = "The path segments have appropriate lengths"
    
    var configuration = AppropriateLengthForURLPathSegmentsConfiguration()
    
    func checkSegment(segment: String, isParameter: Bool) -> Finding? {
        if segment.count < configuration.minimumLength {
            return URLPathLengthFinding.segmentTooShort(segment: segment)
        }
        
        if segment.count > configuration.maximumLength {
            return URLPathLengthFinding.segmentTooLong(segment: segment)
        }
        
        return nil
    }
}

enum URLPathLengthFinding: Finding {
    case segmentTooShort(segment: String)
    case segmentTooLong(segment: String)
    
    var diagnosis: String {
        switch self {
        case .segmentTooShort(let segment):
            return "The path segment \"\(segment)\" is too short"
        case .segmentTooLong(let segment):
            return "The path segment \"\(segment)\" is too long"
        }
    }
}

struct AppropriateLengthForURLPathSegmentsConfiguration: BestPracticeConfiguration {
    var minimumLength = 3
    var maximumLength = 30
    
    func configure() -> BestPractice {
        AppropriateLengthForURLPathSegments(configuration: self)
    }
}