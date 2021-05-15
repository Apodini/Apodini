//
// Created by Andreas Bauer on 24.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class RelationshipInstanceTests: XCTApodiniDatabaseBirdTest {
    let testRelationship = Relationship(name: "test")

    func testSimpleWebService() throws {
        @ComponentBuilder
        var webService: some Component {
            Group("a") {
                Text("Test1")
                    .destination(of: testRelationship)
            }
            Group("b") {
                Text("Test2")
                    .relationship(to: testRelationship)
            }
        }
        
        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<Text>(index: 0) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/a"])
                    })
                },
                CheckHandler<Text>(index: 1) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/b", "test:read": "/a"])
                    })
                }
            ]
        )
    }

    func testWebserviceMultipleSources() throws {
        @ComponentBuilder
        var webService: some Component {
            Group("a") {
                Text("Test1")
                    .destination(of: testRelationship)
            }
            Group("b") {
                Text("Test2")
                    .relationship(to: testRelationship)
            }
            Group("c") {
                Text("Test3")
                    .relationship(to: testRelationship)
            }
        }
        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<Text>(index: 0) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/a"])
                    })
                },
                CheckHandler<Text>(index: 1) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/b", "test:read": "/a"])
                    })
                },
                CheckHandler<Text>(index: 2) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/c", "test:read": "/a"])
                    })
                }
            ]
        )
    }


    func testWebserviceMultipleIllegalDestinations() {
        @ComponentBuilder
        var webService: some Component {
            Group("a") {
                Text("Test1")
                    .destination(of: testRelationship)
            }
            Group("b") {
                Text("Test2")
                    .relationship(to: testRelationship)
            }
            Group("c") {
                Text("Test3")
                    .destination(of: testRelationship)
            }
        }
        
        XCTAssertRuntimeFailure(
            try! self.XCTCheckComponent(
                webService,
                exporter: RelationshipExporter(self.app),
                interfaceExporterVisitors: [RelationshipExporterRetriever()]
            ),
            "Relationship destination must be unique"
        )
    }

    func testWebserviceMultipleDestinations() throws {
        @ComponentBuilder
        var webService: some Component {
            Group("a") {
                Text("Test1")
                    .destination(of: testRelationship)
                Text("Test2")
                    .operation(.update)
                    .destination(of: testRelationship)
            }
            Group("b") {
                Text("Test3")
                    .relationship(to: testRelationship)
            }
        }
        
        try XCTCheckComponent(
            webService,
            exporter: RelationshipExporter(app),
            interfaceExporterVisitors: [RelationshipExporterRetriever()],
            checks: [
                CheckHandler<Text>(index: 0) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/a", "self:update": "/a"])
                    })
                },
                CheckHandler<Text>(index: 1) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:update": "/a", "self:read": "/a"])
                    })
                },
                CheckHandler<Text>(index: 2) {
                    MockRequest<EnrichedContent>(assertion: { enrichedContent in
                        XCTAssertEqual(enrichedContent.formatTestRelationships(), ["self:read": "/b", "test:read": "/a", "test:update": "/a"])
                    })
                }
            ]
        )
    }

    func testWebserviceCyclic() {
        @ComponentBuilder
        var webService: some Component {
            Group("a") {
                Text("Test1")
                    .relationship(to: testRelationship)
                    .destination(of: testRelationship)
            }
        }
        
        XCTAssertRuntimeFailure(
            try! self.XCTCheckComponent(
                webService,
                exporter: RelationshipExporter(self.app),
                interfaceExporterVisitors: [RelationshipExporterRetriever()]
            ),
            "RelationshipBuilder should reject cyclic relationship!"
        )
    }

    func testWebserviceNoDestinations() {
        @ComponentBuilder
        var webService: some Component {
            Group("a") {
                Text("Test1")
                    .relationship(to: testRelationship)
            }
        }

        XCTAssertRuntimeFailure(
            try! self.XCTCheckComponent(
                webService,
                exporter: RelationshipExporter(self.app),
                interfaceExporterVisitors: [RelationshipExporterRetriever()]
            ),
            "RelationshipBuilder should reject relationship instances without destinations!"
        )
    }

    func testWebserviceNoSources() {
        @ComponentBuilder
        var webService: some Component {
            Group("a") {
                Text("Test1")
                    .destination(of: testRelationship)
            }
        }
        
        XCTAssertRuntimeFailure(
            try! self.XCTCheckComponent(
                webService,
                exporter: RelationshipExporter(self.app),
                interfaceExporterVisitors: [RelationshipExporterRetriever()]
            ),
            "RelationshipBuilder should reject relationship instances without sources!"
        )
    }
}
