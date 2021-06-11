//
// Created by Andreas Bauer on 02.06.21.
//

import Foundation

/// Represents a compiler which was unexpected.
struct UnexpectedError: Hashable {
    /// The absolute path of the file the compiler error occurred in.
    let filePath: String
    /// The line where the compiler error occurred
    let line: Int
    /// The column where the compiler error occurred
    let column: Int?
    /// The error message of the compiler error
    let errorMessage: String

    /// The raw line in the build output representing the compiler error.
    let rawLine: String

    func hash(into hasher: inout Hasher) {
        rawLine.hash(into: &hasher)
    }

    static func == (lhs: UnexpectedError, rhs: UnexpectedError) -> Bool {
        lhs.rawLine == rhs.rawLine
    }
}
