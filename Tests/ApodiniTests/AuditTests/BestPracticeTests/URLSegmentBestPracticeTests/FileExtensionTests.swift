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

final class FileExtensionTests: ApodiniTests {
    func testPassingSegments() throws {
        let segments = [
            "images",
            "forests",
            "soccerplayers",
            "masters-theses",
            "russian_dictionary_corpora",
            "longTheses.pdf"
        ]
                
        for segment in segments {
            try assertNoFinding(
                segment: segment,
                bestPractice: FileExtensionConfiguration(allowedExtensions: ["pdf"]).configure()
            )
        }
    }
    
    func testFailingSegments() throws {
        let segments = [
            "image.png",
            "rough.aosidus",
            "v1.jpg.tar.gz",
            "test.swift",
            "lib.o"
        ]
        
        for segment in segments {
            try assertOneFinding(
                segment: segment,
                bestPractice: NoFileExtensionsInURLPathSegments(),
                expectedFinding: URLFileExtensionFinding.fileExtensionFound(segment: segment)
            )
        }
    }
}
