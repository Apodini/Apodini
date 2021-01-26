//
// Created by Andreas Bauer on 25.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class NameShadowingTests: ApodiniTests {
    var aRelationship = Relationship(name: "a")

    struct Number: Handler {
        let int: Int
        func handle() -> Int {
            int
        }
    }

    struct TestData: Content, WithRelationships {
        static var relationships: Relationships {
            Inherits<Int>()
        }
    }

    struct TestDataHandler: Handler {
        func handle() -> TestData {
            TestData()
        }
    }

    @ComponentBuilder
    var webservice: some Component {
        Group("dut") {
            TestDataHandler()
                .relationship(to: aRelationship)

            Number(int: 3) // Number from which TestData inherits has the same structural relationships
                .operation(.update)
            Group("a") {
                Text("TextA")
            }
        }
        Group("other") {
            Text("TextOther")
                .destination(of: aRelationship)
        }
    }

    func testInheritedRelationshipShadowing() {
        return
        // This test cases tests, that inherited relationships do not
        // affect our name shadowing logic:
        // explicit definition (`Relationship` instances) hides -> structural hides -> inherited relationships
        // TODO rest might show shadowed link if shadowing link is hidden
        let context = RelationshipTestContext(app: app, service: webservice)

        let result = context.request(on: 0)
        XCTAssertEqual(
            result.formatTestRelationships(),
            ["self:read": "/dut", "self:update": "/dut", "a:read": "/other"])
    }
}
