//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// BP3
/// Checks whether a URL path segment's length is within the specified.
/// The default minimum and maximum lengths are 3 and 30, respectively.
public class URLPathSegmentLength: URLSegmentBestPractice {
    public static var scope: BestPracticeScopes = .rest
    public static var category: BestPracticeCategories = .urlPath
    var successMessage = "The path segments have appropriate lengths"
    var checkedSegments = [String]()
    
    var configuration = URLPathSegmentLengthConfiguration()
    
    func checkSegment(segment: String, isParameter: Bool) -> Finding? {
        guard !isParameter && !configuration.allowedSegments.contains(segment) else {
            return nil
        }
        
        if segment.count < configuration.minimumLength {
            return URLPathSegmentLengthFinding.segmentTooShort(segment: segment)
        }
        
        if segment.count > configuration.maximumLength {
            return URLPathSegmentLengthFinding.segmentTooLong(segment: segment)
        }
        
        return nil
    }
    
    public required init() { }
    
    init(configuration: URLPathSegmentLengthConfiguration) {
        self.configuration = configuration
    }
}

enum URLPathSegmentLengthFinding: Finding, Equatable {
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

public struct URLPathSegmentLengthConfiguration: BestPracticeConfiguration {
    var minimumLength: Int
    var maximumLength: Int
    var allowedSegments: [String]
    
    public func configure() -> BestPractice {
        URLPathSegmentLength(configuration: self)
    }
    
    public init(minimumLength: Int = 3, maximumLength: Int = 30, allowedSegments: [String] = []) {
        self.minimumLength = minimumLength
        self.maximumLength = maximumLength
        self.allowedSegments = allowedSegments
    }
}
