//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// BP10
/// Checks whether a URL path segment has a file extension, which is discouraged.
public class NoFileExtensionsInURLPathSegments: URLSegmentBestPractice {
    public static var scope: BestPracticeScopes = .rest
    public static var category: BestPracticeCategories = .urlPath
    
    var configuration = FileExtensionConfiguration()
    
    var checkedSegments = [String]()
    
    func checkSegment(segment: String, isParameter: Bool) -> Finding? {
        let dotIndex = segment.firstIndex(of: ".")
        guard let dotIndex = dotIndex else {
            return nil
        }
        let dotIndexInt = segment.distance(from: segment.startIndex, to: dotIndex)
        let extensionLength = segment.count - dotIndexInt - 1
        if configuration.allowedExtensions.contains(String(segment.suffix(extensionLength))) {
            return nil
        }
        return URLFileExtensionFinding.fileExtensionFound(segment: segment)
    }
    
    public required init() { }
    
    init(configuration: FileExtensionConfiguration) {
        self.configuration = configuration
    }
}

public struct FileExtensionConfiguration: BestPracticeConfiguration {
    var allowedExtensions: [String]
    
    public func configure() -> BestPractice {
        NoFileExtensionsInURLPathSegments(configuration: self)
    }
    
    public init(allowedExtensions: [String] = []) {
        self.allowedExtensions = allowedExtensions
    }
}

enum URLFileExtensionFinding: Finding, Equatable {
    case fileExtensionFound(segment: String)
    
    var diagnosis: String {
        switch self {
        case .fileExtensionFound(let segment):
            return "The path segment \(segment) has a file extension."
        }
    }
}
