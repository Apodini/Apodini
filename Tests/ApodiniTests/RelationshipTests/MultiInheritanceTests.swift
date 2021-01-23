//
// Created by Andreas Bauer on 24.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class MultiInheritanceTests: ApodiniTests {
    struct TestA: Content, WithRelationships {
        var testA: String
        var customC: String

        static var relationships: Relationships {
            Inherits<TestB> {
                Identifying<TestC>(at: \.customC)
            }
        }
    }

    struct TestB: Content, WithRelationships {
        var id: String
        var cId: String

        static var relationships: Relationships {
            Inherits<TestC>(at: \.cId)
        }
    }

    struct TestZ: Content, WithRelationships {
        var id: String
        var cId: String

        static var relationships: Relationships {
            Inherits<TestC>(at: \.cId)
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
        @Parameter
        var cId: String
        func handle() -> TestC {
            TestC(id: cId)
        }
    }

    struct TextParameter: Handler {
        @Parameter
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

        let resultC = context.request(on: 4, parameters: "cId")
        XCTAssertEqual(
            resultC.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/testC/cId", "text:read": "/testC/cId/text"])

        let resultB = context.request(on: 2)
        XCTAssertEqual(
            resultB.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/testC/TestCId", "bText:read": "/testB/bText", "text:read": "/testC/TestCId/text"])

        let resultA = context.request(on: 0)
        XCTAssertEqual(
            resultA.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/testB", "aText:read": "/testA/aText", "bText:read": "/testB/bText", "text:read": "/testC/customCId/text"])

        let resultZ = context.request(on: 6)
        XCTAssertEqual(
            resultZ.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/testC/TestCZId", "text:read": "/testZ/text"]) // own /text shadows the inherited /text
    }

    struct CycleA: Content, WithRelationships {
        static var relationships: Relationships {
            Inherits<CycleB>()
        }
    }

    struct CycleB: Content, WithRelationships {
        static var relationships: Relationships {
            Inherits<CycleC>()
        }
    }

    struct CycleC: Content, WithRelationships {
        static var relationships: Relationships {
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
