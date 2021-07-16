//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
