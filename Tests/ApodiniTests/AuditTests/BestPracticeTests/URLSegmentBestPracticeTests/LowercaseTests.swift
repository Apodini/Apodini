//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
@testable import Apodini
@testable import ApodiniAudit
@testable import ApodiniREST

final class LowercaseTests: ApodiniTests {
    func testPassingSegments() throws {
        let segments = [
            "images",
            "forests",
            "soccerplayers",
            "masters-theses",
            "russian_dictionary_corpora",
            "longtheses.pdf"
        ]
                
        for segment in segments {
            try assertNoFinding(
                segment: segment,
                bestPractice: LowercaseURLPathSegments()
            )
        }
    }
    
    func testFailingSegments() throws {
        let segments = [
            "Image",
            "helloThere",
            "DELETE",
            "weIrd",
            "O"
        ]
        
        for segment in segments {
            try assertOneFinding(
                segment: segment,
                bestPractice: LowercaseURLPathSegments(),
                expectedFinding: LowercasePathSegmentsFinding.uppercaseCharacterFound(segment: segment)
            )
        }
    }
}
