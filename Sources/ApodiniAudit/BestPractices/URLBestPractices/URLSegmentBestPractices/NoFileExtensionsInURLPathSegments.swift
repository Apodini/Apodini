//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

struct NoFileExtensionsInURLPathSegments: URLSegmentBestPractice {
    static var scope: BestPracticeScopes = .rest
    static var category: BestPracticeCategories = .urlPath
    var successMessage = "The path segments do not contain any uppercase letters"
    var allowedExtensions: [String] = []
    /// The minimum distance from the end of the segment that a dot has to have
    /// in order to not be recognized as a file extension.
    /// If this is 4, then 'html' would not be recognized as a file extension
    var minDistanceFromEnd = 5
    
    func checkSegment(segment: String) -> String? {
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
