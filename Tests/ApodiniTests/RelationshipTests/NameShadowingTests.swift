//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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

    struct TestData: Content {
        static var metadata: Metadata {
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
        // This test cases tests, that inherited relationships do not
        // affect our name shadowing logic:
        // explicit definition (`Relationship` instances) hides -> structural hides -> inherited relationships
        let context = RelationshipTestContext(app: app, service: webservice)

        let result = context.request(on: 0)
        XCTAssertEqual(
            result.formatTestRelationships(),
            ["self:read": "/dut", "self:update": "/dut", "a:read": "/other"])
    }
}
