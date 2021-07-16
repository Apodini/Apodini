//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import XCTest
@testable import Apodini

final class RelationshipPreliminaryTests: XCTestCase {
    struct Model: Identifiable {
        var id: String
    }

    struct Model2: Identifiable {
        var id: String
    }

    func testReferenceCreation() {
        _ = RelationshipReference<Model, Model2>(as: "reference", identifiedBy: \Model.id)
    }

    func testInheritanceCreation() {
        _ = RelationshipInheritance<Model, Model2>(identifiedBy: \Model.id)
    }
}
