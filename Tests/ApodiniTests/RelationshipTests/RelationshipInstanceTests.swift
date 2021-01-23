//
// Created by Andreas Bauer on 24.01.21.
//

import XCTest
import XCTApodini
@testable import Apodini

class RelationshipInstanceTests: ApodiniTests {
    let testRelationship = Relationship(name: "test")

    @ComponentBuilder
    var simpleWebservice: some Component {
        Group("a") {
            Text("Test1")
                .destination(of: testRelationship)
        }
        Group("b") {
            Text("Test2")
                .relationship(to: testRelationship)
        }
    }

    func testSimpleWebService() {
        let context = RelationshipTestContext(app: app, service: simpleWebservice)

        let resultA = context.request(on: 0)
        XCTAssertEqual(
            resultA.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/a"])

        let resultB = context.request(on: 1)
        XCTAssertEqual(
            resultB.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/b", "test:read": "/a"])
    }


    @ComponentBuilder
    var webserviceMultipleSources: some Component {
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

    func testWebserviceMultipleSources() {
        let context = RelationshipTestContext(app: app, service: webserviceMultipleSources)

        let resultA = context.request(on: 0)
        XCTAssertEqual(
            resultA.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/a"])

        let resultB = context.request(on: 1)
        XCTAssertEqual(
            resultB.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/b", "test:read": "/a"])

        let resultC = context.request(on: 2)
        XCTAssertEqual(
            resultC.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/c", "test:read": "/a"])
    }


    @ComponentBuilder
    var webserviceMultipleIllegalDestinations: some Component {
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

    func testWebserviceMultipleIllegalDestinations() {
        XCTAssertRuntimeFailure(RelationshipTestContext(app: self.app, service: self.webserviceMultipleIllegalDestinations),
                                "Relationship destination must be unique")
    }


    @ComponentBuilder
    var webServiceMultipleDestinations: some Component {
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

    func testWebserviceMultipleDestinations() {
        let context = RelationshipTestContext(app: app, service: webServiceMultipleDestinations)

        let resultA1 = context.request(on: 0)
        XCTAssertEqual(
            resultA1.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/a", "self:update": "/a"])

        let resultA2 = context.request(on: 1)
        XCTAssertEqual(
            resultA2.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:update": "/a", "self:read": "/a"])

        let resultB = context.request(on: 2)
        XCTAssertEqual(
            resultB.formatRelationships(into: [:], with: TestingRelationshipFormatter(), includeSelf: true),
            ["self:read": "/b", "test:read": "/a", "test:update": "/a"])
    }


    @ComponentBuilder
    var webserviceCyclic: some Component {
        Group("a") {
            Text("Test1")
                .relationship(to: testRelationship)
                .destination(of: testRelationship)
        }
    }

    func testWebserviceCyclic() {
        XCTAssertRuntimeFailure(RelationshipTestContext(app: self.app, service: self.webserviceCyclic),
                                "RelationshipBuilder should reject cyclic relationship!")
    }


    @ComponentBuilder
    var webserviceNoDestinations: some Component {
        Group("a") {
            Text("Test1")
                .relationship(to: testRelationship)
        }
    }

    func testWebserviceNoDestinations() {
        XCTAssertRuntimeFailure(RelationshipTestContext(app: self.app, service: self.webserviceNoDestinations),
                                "RelationshipBuilder should reject relationship instances without destinations!")
    }


    @ComponentBuilder
    var webserviceNoSources: some Component {
        Group("a") {
            Text("Test1")
                .destination(of: testRelationship)
        }
    }

    func testWebserviceNoSources() {
        XCTAssertRuntimeFailure(RelationshipTestContext(app: self.app, service: self.webserviceNoSources),
                                "RelationshipBuilder should reject relationship instances without sources!")
    }
}
