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

final class NumbersOrSymbolsTests: ApodiniTests {
    func testPassingSegments() throws {
        let segments = [
            "imag%s",
            "forests",
            "soccerplayers",
            "masters-theses",
            "longtheses"
        ]
                
        for segment in segments {
            try assertNoFinding(
                segment: segment,
                bestPractice: NumberOrSymbolConfiguration(allowedSymbols: ["%"]).configure()
            )
        }
    }
    
    func testFailingSegments() throws {
        let segments = [
            "imag&e",
            ".test",
            "$what",
            "@me",
            "under_score"
        ]
        
        for segment in segments {
            try assertOneFinding(
                segment: segment,
                bestPractice: NumberOrSymbolConfiguration().configure(),
                expectedFinding: NumberOrSymbolsInURLFinding.nonLetterCharacterFound(segment: segment)
            )
        }
    }
}
