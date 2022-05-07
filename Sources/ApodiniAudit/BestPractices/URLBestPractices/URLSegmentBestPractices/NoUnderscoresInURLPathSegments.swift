//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

struct NoUnderscoresInURLPathSegments: URLSegmentBestPractice {
    var scope: BestPracticeScopes = .all
    var category: BestPracticeCategories = .urlPath
    var successMessage = "The path segments do not contain any underscores"
    
    func checkSegment(segment: String) -> String? {
        if segment.contains("_") {
            return "The path segment \(segment) contains one or more underscores"
        }
        return nil
    }
}
