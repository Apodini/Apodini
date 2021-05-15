//
// Created by Andreas Bauer on 24.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class MultiInheritanceTests: XCTApodiniDatabaseBirdTest {
    struct TestA: Content, Equatable, WithRelationships {
        var testA: String
        var customC: String

        static var relationships: Relationships {
            Inherits<TestB> {
                Identifying<TestC>(identifiedBy: \.customC)
            }
        }
    }

    struct TestB: Content, Equatable, WithRelationships {
        var id: String
        var cId: String

        static var relationships: Relationships {
            Inherits<TestC>(identifiedBy: \.cId)
        }
    }

    struct TestZ: Content, Equatable, WithRelationships {
        var id: String
        var cId: String

        static var relationships: Relationships {
            Inherits<TestC>(identifiedBy: \.cId)
        }
    }

    struct TestC: Content, Equatable, Identifiable {
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
    
    
    func testMultiInheritance() throws {
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
        
        try XCTCheckComponent(
            webserviceMultiInheritance,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<TestCHandler>(index: 4) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/testC/cId", "text:read": "/testC/cId/text"]
                        )
                    }) {
                        UnnamedParameter("cId")
                    }
                },
                CheckHandler<TestBHandler>(index: 2) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/testC/TestCId", "bText:read": "/testB/bText", "text:read": "/testC/TestCId/text"]
                        )
                    })
                },
                CheckHandler<TestAHandler>(index: 0) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/testB", "aText:read": "/testA/aText", "bText:read": "/testB/bText", "text:read": "/testC/customCId/text"]
                        )
                    })
                },
                CheckHandler<TestZHandler>(index: 6) { // own /text shadows the inherited /text
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/testC/TestCZId", "text:read": "/testZ/text"]
                        )
                    })
                }
            ]
        )
    }

    func testInheritanceWithCycle() {
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
        var webService: some Component {
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
        
        XCTAssertRuntimeFailure(
            try! self.XCTCheckComponent(
                webService,
                exporter: RelationshipExporter(self.app),
                interfaceExporterVisitors: [RelationshipExporterRetriever()]
            )
        )
    }
}
