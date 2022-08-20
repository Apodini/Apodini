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

final class GrammaricalNumberTests: ApodiniTests {
    func testPassingNouns() throws {
        let nouns = [
            "images",
            "forests",
            "soccerplayers",
            "masters-theses",
            "russian_dictionary_corpora",
            "longTheses"
        ]
                
        for noun in nouns {
            try assertNoFinding(
                segment: noun,
                bestPractice: PluralSegmentForStoresAndCollections()
            )
        }
    }
    
    func testFailingNouns() throws {
        let nouns = [
            "image",
            "largeFile",
            "exceltable",
            "masters-thesis",
            "classical_concert",
            "go",
            "12493"
        ]
        
        for noun in nouns {
            try assertOneFinding(
                segment: noun,
                bestPractice: PluralSegmentForStoresAndCollections(),
                expectedFinding: BadCollectionSegmentName.nonPluralBeforeParameter(noun)
            )
        }
    }
}
