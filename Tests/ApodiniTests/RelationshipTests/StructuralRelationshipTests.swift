//
// Created by Andreas Bauer on 23.01.21.
//

@testable import Apodini
import XCTApodini


class RelationshipTests: XCTApodiniDatabaseBirdTest {
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
    
    
    func testStructuralRelationships() throws {
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

        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<Text>(index: 0) { // handling "Test1"
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            [
                                "self:read": "/a", "b_c:read": "/a/b/{id}/c", "b_c:update": "/a/b/{id}/c/{id2}",
                                "b_d:read": "/a/b/{id}/d"
                            ]
                        )
                    })
                },
                CheckHandler<TextParameterized>(index: 1) { // handling "Test2"
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/a/b/value0/c", "id2:update": "/a/b/value0/c/{id2}"]
                        )
                    }) {
                        UnnamedParameter("value0")
                    }
                },
                CheckHandler<TextParameterized>(index: 2) { // handling "Test3"
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:update": "/a/b/value0/c/value1"]
                        )
                    }) {
                        UnnamedParameter("value0")
                        UnnamedParameter("value1")
                    }
                },
                CheckHandler<TextParameterized>(index: 3) {  // handling "Test4"
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/a/b/value0/d"]
                        )
                    }) {
                        UnnamedParameter("value0")
                    }
                }
            ]
        )
    }

    func testModifiedStructuralRelationships() throws {
        @ComponentBuilder
        var webService: some Component {
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
        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<Text>(index: 0) { // handling "Test1"
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            [
                                "self:read": "/a", "namedc:read": "/a/b/{id}/c", "namedTest:read": "/a/b/{id}/d",
                                "namedc:update": "hidden:/a/b/{id}/c/{id2}", "namede:read": "hidden:/a/b/{id}/e"
                            ]
                        )
                    })
                },
                CheckHandler<TextParameterized>(index: 1) { // handling "Test2"
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/a/b/value0/c", "id2:update": "/a/b/value0/c/{id2}"]
                        )
                    }) {
                        UnnamedParameter("value0")
                    }
                },
                CheckHandler<TextParameterized2>(index: 2) { // handling "Test3"
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:update": "/a/b/value0/c/value1"]
                        )
                    }) {
                        UnnamedParameter("value0")
                        UnnamedParameter("value1")
                    }
                },
                CheckHandler<TextParameterized>(index: 3) { // handling "Test4"
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/a/b/value0/d"]
                        )
                    }) {
                        UnnamedParameter("value0")
                    }
                },
                CheckHandler<TextParameterized>(index: 4) { // handling "Test5"
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(
                            enrichedContent.formatTestRelationships(),
                            ["self:read": "/a/b/value0/e"]
                        )
                    }) {
                        UnnamedParameter("value0")
                    }
                }
            ]
        )
    }
}
