//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation

/// BP2 & BP8
/// Checks whether a URL path segment contains any numbers or symbols, which is discouraged.
public class NoNumbersOrSymbolsInURLPathSegments: URLSegmentBestPractice {
    public static var scope: BestPracticeScopes = .all
    public static var category: BestPracticeCategories = .urlPath
    
    var checkedSegments = [String]()
    
    var configuration = NumberOrSymbolConfiguration()
    
    func checkSegment(segment: String, isParameter: Bool) -> Finding? {
        if segment.contains(where: { char in
            !char.isLetter && !configuration.allowedSymbols.contains(char)
        }) {
            return NumberOrSymbolsInURLFinding.nonLetterCharacterFound(segment: segment)
        }
        return nil
    }
    
    public required init() { }
    
    init(configuration: NumberOrSymbolConfiguration) {
        self.configuration = configuration
    }
}

public struct NumberOrSymbolConfiguration: BestPracticeConfiguration {
    var allowedSymbols: [Character] = ["-"]
    
    public func configure() -> BestPractice {
        NoNumbersOrSymbolsInURLPathSegments(configuration: self)
    }
    
    public init(allowedSymbols: [Character] = []) {
        self.allowedSymbols += allowedSymbols
    }
}

enum NumberOrSymbolsInURLFinding: Finding, Equatable {
    case nonLetterCharacterFound(segment: String)
    
    var diagnosis: String {
        switch self {
        case .nonLetterCharacterFound(let segment):
            return "The segment \(segment) contains one or more non-letter characters."
        }
    }
}
