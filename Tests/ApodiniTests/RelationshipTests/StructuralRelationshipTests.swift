//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import XCTest
@testable import Apodini

class RelationshipTests: ApodiniTests {
    @PathParameter
    var id: String
    @PathParameter
    var id2: String

    struct TextParameterized: Handler {
        var text: String
        @Binding
        var id: String

        func handle() -> String {
            text
        }
    }

    struct TextParameterized2: Handler {
        var text: String
        @Binding
        var id: String
        @Binding
        var id2: String

        func handle() -> String {
            text
        }
    }

    @ComponentBuilder
    var webService: some Component {
        Group("a") {
            Text("Test1")
            Group("b", $id) {
                Group("c") {
                    TextParameterized(text: "Test2", id: $id)
                    TextParameterized2(text: "Test3", id: $id, id2: $id2)
                        .operation(.update)
                }
                Group("d") {
                    TextParameterized(text: "Test4", id: $id)
                }
            }
        }
    }

    func testStructuralRelationships() throws {
        let context = RelationshipTestContext(app: app, service: webService)

        let result0 = context.request(on: 0) // handling "Test1"
        XCTAssertEqual(
            result0.formatTestRelationships(),
            [
                "self:read": "/a", "b_c:read": "/a/b/{id}/c", "b_c:update": "/a/b/{id}/c/{id2}",
                "b_d:read": "/a/b/{id}/d"
            ])

        let result1 = context.request(on: 1, parameters: "value0") // handling "Test2"
        XCTAssertEqual(
            result1.formatTestRelationships(),
            ["self:read": "/a/b/value0/c", "id2:update": "/a/b/value0/c/{id2}"])

        let result2 = context.request(on: 2, parameters: "value0", "value1") // handling "Test3"
        XCTAssertEqual(
            result2.formatTestRelationships(),
            ["self:update": "/a/b/value0/c/value1"])

        let result3 = context.request(on: 3, parameters: "value0") // handling "Test4"
        XCTAssertEqual(
            result3.formatTestRelationships(),
            ["self:read": "/a/b/value0/d"])
    }

    @ComponentBuilder
    var modifiedWebService: some Component {
        Group("a") {
            Text("Test1")
            Group {
                "b".relationship(name: "named")
                $id.hideLink(of: .update)
            } content: {
                Group("c") {
                    TextParameterized(text: "Test2", id: $id)
                    TextParameterized2(text: "Test3", id: $id, id2: $id2)
                        .operation(.update)
                }
                Group("d".relationship(name: "Test")) {
                    TextParameterized(text: "Test4", id: $id)
                }
                Group("e".hideLink()) {
                    TextParameterized(text: "Test5", id: $id)
                }
            }
        }
    }

    func testModifiedStructuralRelationships() throws {
        let context = RelationshipTestContext(app: app, service: modifiedWebService)

        let result0 = context.request(on: 0) // handling "Test1"
        XCTAssertEqual(
            result0.formatTestRelationships(),
            [
                "self:read": "/a", "namedc:read": "/a/b/{id}/c", "namedTest:read": "/a/b/{id}/d",
                "namedc:update": "hidden:/a/b/{id}/c/{id2}", "namede:read": "hidden:/a/b/{id}/e"
            ])

        let result1 = context.request(on: 1, parameters: "value0") // handling "Test2"
        XCTAssertEqual(
            result1.formatTestRelationships(),
            ["self:read": "/a/b/value0/c", "id2:update": "/a/b/value0/c/{id2}"])

        let result2 = context.request(on: 2, parameters: "value0", "value1") // handling "Test3"
        XCTAssertEqual(
            result2.formatTestRelationships(),
            ["self:update": "/a/b/value0/c/value1"])

        let result3 = context.request(on: 3, parameters: "value0") // handling "Test4"
        XCTAssertEqual(
            result3.formatTestRelationships(),
            ["self:read": "/a/b/value0/d"])

        let result4 = context.request(on: 4, parameters: "value0") // handling "Test4"
        XCTAssertEqual(
            result4.formatTestRelationships(),
            ["self:read": "/a/b/value0/e"])
    }
}
