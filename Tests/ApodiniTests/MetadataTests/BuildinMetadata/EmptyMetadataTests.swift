//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
import XCTest
import XCTApodini

final class EmptyMetadataTests: ApodiniTests {
    func testEmptyMetadataValue() {
        XCTAssertRuntimeFailure(EmptyHandlerMetadata().value)
        XCTAssertRuntimeFailure(EmptyComponentOnlyMetadata().value)
        XCTAssertRuntimeFailure(EmptyWebServiceMetadata().value)
        XCTAssertRuntimeFailure(EmptyComponentMetadata().value)
        XCTAssertRuntimeFailure(EmptyContentMetadata().value)
    }
}
