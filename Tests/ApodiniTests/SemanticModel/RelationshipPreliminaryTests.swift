//
// Created by Andi on 21.12.20.
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
        _ = RelationshipReference<Model, Model2>(as: "reference", at: \Model.id)
    }

    func testInheritanceCreation() {
        _ = RelationshipInheritance<Model, Model2>(at: \Model.id)
    }
}
