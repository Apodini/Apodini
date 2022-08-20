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

final class CRUDVerbTests: ApodiniTests {
    func testPassingVerbs() throws {
        let segments = [
            "images",
            "forests",
            "soccerplayers",
            "masters-theses",
            "russian_dictionary_corpora",
            "longTheses"
        ]
                
        for segment in segments {
            try assertNoFinding(
                segment: segment,
                bestPractice: NoCRUDVerbsInURLPathSegments()
            )
        }
    }
    
    func testFailingVerbs() throws {
        let segments = [
            "getImage",
            "setPicture",
            "DELETEAPPLICATION",
            "createDraft",
            "removeParent",
            "makePost"
        ]
        
        for segment in segments {
            try assertOneFinding(
                segment: segment,
                bestPractice: CRUDVerbConfiguration(forbiddenVerbs: ["make"]).configure(),
                expectedFinding: URLCRUDVerbsFinding.crudVerbFound(segment: segment)
            )
        }
    }
}
