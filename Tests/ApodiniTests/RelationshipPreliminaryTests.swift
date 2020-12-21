//
// Created by Andi on 21.12.20.
//

import XCTest
@testable import Apodini

final class RelationshipPreliminaryTests: XCTestCase {
    struct Model: Identifiable {
        var id: String
    }

    func testReferenceCreation() {
        let model = Model(id: "1234")

        let reference = SomeRelationshipReference<Model, Model>(at: \Model.id, as: "reference")
        XCTAssertEqual(model.id, reference.identifier(for: model))
    }

    func testInheritanceCreation() {
        let model = Model(id: "1234")

        let inheritance = SomeRelationshipInheritance<Model, Model>(at: \Model.id)
        XCTAssertEqual(model.id, inheritance.identifier(for: model))
        XCTAssertEqual(inheritance.name, "self")
    }
}
