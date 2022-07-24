//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// BP8
class NoUnderscoresInURLPathSegments: URLSegmentBestPractice {
    static var scope: BestPracticeScopes = .all
    static var category: BestPracticeCategories = .urlPath
    
    var checkedSegments = [String]()
    
    func checkSegment(segment: String, isParameter: Bool) -> Finding? {
        if segment.contains("_") {
            return URLSegmentsUnderscoreFinding.underscoreFound(segment: segment)
        }
        return nil
    }
    
    required init() { }
}


enum URLSegmentsUnderscoreFinding: Finding {
    case underscoreFound(segment: String)
    
    var diagnosis: String {
        switch self {
        case .underscoreFound(let segment):
            return "The path segment \(segment) contains one or more underscores"
        }
    }
}
