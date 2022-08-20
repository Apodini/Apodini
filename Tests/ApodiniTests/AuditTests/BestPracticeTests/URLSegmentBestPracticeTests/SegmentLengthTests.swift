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

final class SegmentLengthTests: ApodiniTests {
    func testPassingSegments() throws {
        let segments = [
            "de",
            "fore",
            "soccerplay",
            "masters",
            "longtheses"
        ]
                
        for segment in segments {
            try assertNoFinding(
                segment: segment,
                bestPractice: URLPathSegmentLengthConfiguration(minimumLength: 4, maximumLength: 10, allowedSegments: ["de"]).configure()
            )
        }
    }
    
    func testFailingSegments() throws {
        let segments = [
            "de",
            "s",
            "v",
            "asdfghjkltu",
            "mainBranchActor"
        ]
        
        for segment in segments {
            let finding: URLPathSegmentLengthFinding
            if segment.count < 3 {
                finding = .segmentTooShort(segment: segment)
            } else {
                finding = .segmentTooLong(segment: segment)
            }
            try assertOneFinding(
                segment: segment,
                bestPractice: URLPathSegmentLengthConfiguration(minimumLength: 3, maximumLength: 10).configure(),
                expectedFinding: finding
            )
        }
    }
}
