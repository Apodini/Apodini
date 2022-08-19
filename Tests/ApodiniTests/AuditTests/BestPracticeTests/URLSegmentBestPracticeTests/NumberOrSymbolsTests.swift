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
    func testPassingNouns() throws {
        let nouns = [
            "images",
            "forests",
            "soccerplayers",
            "masters-theses",
            "russian_dictionary_corpora",
            "longTheses"
        ]
        
        var webService = BestPracticeWebService()
        
        for noun in nouns {
            webService.pluralString = noun
            let bestPractice = PluralSegmentForStoresAndCollections()
            let endpoint = try getEndpointFromWebService(webService, app, "GetStoreHandler")
            let audit = bestPractice.check(for: endpoint, app)
            XCTAssert(audit.findings.isEmpty, noun)
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
        
        var webService = BestPracticeWebService()
        
        for noun in nouns {
            webService.pluralString = noun
            let bestPractice = PluralSegmentForStoresAndCollections()
            let endpoint = try getEndpointFromWebService(webService, app, "GetStoreHandler")
            let audit = bestPractice.check(for: endpoint, app)
            XCTAssertEqual(audit.findings.count, 1)
            let finding = audit.findings[0]
            guard case BadCollectionSegmentName.nonPluralBeforeParameter(noun) = finding else {
                XCTFail(noun)
                continue
            }
        }
    }
}
