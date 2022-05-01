//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import XCTest
import ApodiniUtils


private struct Book: Codable, Equatable {
    let title: String
    let author: String
    let yearPublished: Int
    let coverImage: Data?
}


class AnyCodableTests: XCTestCase {
    func testEncodeToJSONFile() throws {
        let book = Book(
            title: "A Game of Thrones",
            author: "George R. R. Martin",
            yearPublished: 1996,
            coverImage: .init([0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9])
        )
        let tmpPath = FileManager.default.getTemporaryFileUrl(fileExtension: "json")
        try book.writeJSON(to: tmpPath)
        let decodedBook = try Book(decodingJSONAt: tmpPath)
        XCTAssertEqual(book, decodedBook)
    }
}
