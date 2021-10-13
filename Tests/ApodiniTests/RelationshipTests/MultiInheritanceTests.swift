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

class MultiInheritanceTests: XCTApodiniTest {
    struct TestA: Content {
        var testA: String
        var customC: String

        static var metadata: Metadata {
            Inherits<TestB> {
                Identifying<TestC>(identifiedBy: \.customC)
            }
        }
    }

    struct TestB: Content {
        var id: String
        var cId: String

        static var metadata: Metadata {
            Inherits<TestC>(identifiedBy: \.cId)
        }
    }

    struct TestZ: Content {
        var id: String
        var cId: String

        static var metadata: Metadata {
            Inherits<TestC>(identifiedBy: \.cId)
        }
    }

    struct TestC: Content, Identifiable {
        var id: String
    }

    struct TestAHandler: Handler {
        func handle() -> TestA {
            TestA(testA: "TestA", customC: "customCId")
        }
    }

    struct TestBHandler: Handler {
        func handle() -> TestB {
            TestB(id: "TestB", cId: "TestCId")
        }
    }

    struct TestZHandler: Handler {
        func handle() -> TestZ {
            TestZ(id: "TestZ", cId: "TestCZId")
        }
    }

    struct TestCHandler: Handler {
        @Binding
        var cId: String
        
        
        func handle() -> TestC {
            TestC(id: cId)
        }
    }

    struct TextParameter: Handler {
        @Binding
        var textId: String
        
        
        var text: String
        func handle() -> String {
            text
        }
    }

    @PathParameter(identifying: TestC.self)
    var cId: String

    @ComponentBuilder
    var webserviceMultiInheritance: some Component {
        // The order here is important as its test the ordering capabilities of the TypeIndex
        Group("testA") {
            TestAHandler() // 0
            Group("aText") {
                Text("text") // 1
            }
        }
        Group("testC", $cId) {
            TestCHandler(cId: $cId) // 4
            Group("text") {
                TextParameter(textId: $cId, text: "text") // 5
            }
        }
        Group("testZ") {
            TestZHandler() // 6
            Group("text") { // overshadows /testC/text
                Text("text") // 7
            }
        }
        Group("testB") {
            TestBHandler() // 2
            Group("bText") {
                Text("text") // 3
            }
        }
    }

    func testMultiInheritance() {
        let context = RelationshipTestContext(app: app, service: webserviceMultiInheritance)

        let resultC = context.request(on: 4) {
            UnnamedParameter("cID")
        }
        XCTAssertEqual(
            resultC.formatTestRelationships(),
            ["self:read": "/testC/cId", "text:read": "/testC/cId/text"])

        let resultB = context.request(on: 2)
        XCTAssertEqual(
            resultB.formatTestRelationships(),
            ["self:read": "/testC/TestCId", "bText:read": "/testB/bText", "text:read": "/testC/TestCId/text"])

        let resultA = context.request(on: 0)
        XCTAssertEqual(
            resultA.formatTestRelationships(),
            ["self:read": "/testB", "aText:read": "/testA/aText", "bText:read": "/testB/bText", "text:read": "/testC/customCId/text"])

        let resultZ = context.request(on: 6)
        XCTAssertEqual(
            resultZ.formatTestRelationships(),
            ["self:read": "/testC/TestCZId", "text:read": "/testZ/text"]) // own /text shadows the inherited /text
    }

    struct CycleA: Content {
        static var metadata: Metadata {
            Inherits<CycleB>()
        }
    }

    struct CycleB: Content {
        static var metadata: Metadata {
            Inherits<CycleC>()
        }
    }

    struct CycleC: Content {
        static var metadata: Metadata {
            Inherits<CycleA>()
        }
    }

    struct CycleAHandler: Handler {
        func handle() -> CycleA {
            CycleA()
        }
    }

    struct CycleBHandler: Handler {
        func handle() -> CycleB {
            CycleB()
        }
    }

    struct CycleCHandler: Handler {
        func handle() -> CycleC {
            CycleC()
        }
    }

    @ComponentBuilder
    var cyclicWebservice: some Component {
        Group("a") {
            CycleAHandler()
        }
        Group("b") {
            CycleBHandler()
        }
        Group("c") {
            CycleCHandler()
        }
    }

    func testInheritanceWithCycle() {
        XCTAssertRuntimeFailure(RelationshipTestContext(app: self.app, service: self.cyclicWebservice))
    }
}
