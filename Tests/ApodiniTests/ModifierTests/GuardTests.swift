//
//  GuardTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import XCTVapor
import XCTApodini
import protocol FluentKit.Database
@testable import Apodini
@testable import ApodiniREST
@testable import ApodiniVaporSupport


final class GuardTests: ApodiniTests {
    private static var guardExpectation: XCTestExpectation?
    
    
    func testSyncGuard() throws {
        struct TestSyncGuard: SyncGuard {
            func check() {
                guard let guardExpectation = GuardTests.guardExpectation else {
                    fatalError("The test expectation must be set before testing `TestGuard`")
                }
                guardExpectation.fulfill()
            }
        }
        
        GuardTests.guardExpectation = self.expectation(description: "Guard is executed")
        
        struct TestWebService: WebService {
            var version = Version(prefix: "v", major: 2, minor: 1, patch: 0)
            
            var content: some Component {
                Text("Hello")
                    .guard(TestSyncGuard())
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        
        try app.vapor.app.test(.GET, "/v2/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
            waitForExpectations(timeout: 0, handler: nil)
        }
    }
    
    func testGuard() throws {
        struct TestGuard: Guard {
            @Apodini.Environment(\.database)
            var database: Database
            
            func check() -> EventLoopFuture<Void> {
                guard let guardExpectation = GuardTests.guardExpectation else {
                    fatalError("The test expectation must be set before testing `TestGuard`")
                }
                guardExpectation.fulfill()
                
                return database.eventLoop.makeSucceededFuture(Void())
            }
        }
        
        GuardTests.guardExpectation = self.expectation(description: "Guard is executed")
        
        struct TestWebService: WebService {
            var version = Version(prefix: "v", major: 2, minor: 1, patch: 0)
            
            var content: some Component {
                Text("Hello")
                    .guard(TestGuard())
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        
        try app.vapor.app.test(.GET, "/v2/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
            waitForExpectations(timeout: 0, handler: nil)
        }
    }
    
    func testResetGuard() throws {
        struct TestSyncGuard: SyncGuard {
            func check() {
                XCTFail("Check must never be called!")
            }
        }
        
        struct TestWebService: WebService {
            var content: some Component {
                Group {
                    Text("Hello")
                        .resetGuards()
                }.guard(TestSyncGuard())
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
        }
    }
    
    func testResetGuardOnMultipleLayers() throws {
        struct TestSyncGuard: SyncGuard {
            static var collectedOrder: [Int] = []

            let order: Int

            func check() {
                TestSyncGuard.collectedOrder.append(order)
                guard let guardExpectation = GuardTests.guardExpectation else {
                    fatalError("The test expectation must be set before testing `TestGuard`")
                }
                guardExpectation.fulfill()
            }
        }
        
        GuardTests.guardExpectation = self.expectation(description: "Guard is executed")
        GuardTests.guardExpectation?.expectedFulfillmentCount = 3
        
        struct TestWebService: WebService {
            var content: some Component {
                Group {
                    Group {
                        Text("Hello")
                            .guard(TestSyncGuard(order: 3))
                            .guard(TestSyncGuard(order: 4))
                    }.guard(TestSyncGuard(order: 2))
                }.guard(TestSyncGuard(order: 1))
                .resetGuards()
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        
        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
            XCTAssertEqual(TestSyncGuard.collectedOrder, [2, 3, 4])
            waitForExpectations(timeout: 0, handler: nil)
        }
    }
    
    func testResetGuardOnly() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hello")
                    .resetGuards()
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
        }
    }
    
    func testResetGuardOnSameComponent() throws {
        struct TestSyncGuard: SyncGuard {
            func check() {
                XCTFail("Check must never be called!")
            }
        }
        
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hello")
                    .guard(TestSyncGuard())
                    .resetGuards()
            }

            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
        }
    }
    
    func testResetGuardOnSameComponentWithNoEffect() throws {
        struct TestSyncGuard: SyncGuard {
            func check() {
                guard let guardExpectation = GuardTests.guardExpectation else {
                    fatalError("The test expectation must be set before testing `TestGuard`")
                }
                guardExpectation.fulfill()
            }
        }
        
        GuardTests.guardExpectation = self.expectation(description: "TestSyncGuard is executed")
        
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hello")
                    .resetGuards()
                    .guard(TestSyncGuard())
            }
            
            var configuration: Configuration {
                REST()
            }
        }
        
        TestWebService.start(app: app)
        
        try app.vapor.app.test(.GET, "/v1/") { res in
            XCTAssertEqual(res.status, .ok)
            
            struct Content: Decodable {
                let data: String
            }
            
            let content = try res.content.decode(Content.self)
            XCTAssert(content.data == "Hello")
            waitForExpectations(timeout: 0, handler: nil)
        }
    }

    func testGuardMetadata() throws {
        struct MetadataGuard: SyncGuard {
            static var metadataGuardExpectation: XCTestExpectation?

            let order: Int
            func check() {
                TestHandler.collectedOrder.append(order)
                MetadataGuard.metadataGuardExpectation?.fulfill()
            }
        }

        struct ModifierGuard: SyncGuard {
            static var modifierGuardExpectation: XCTestExpectation?

            let order: Int
            func check() {
                TestHandler.collectedOrder.append(order)
                ModifierGuard.modifierGuardExpectation?.fulfill()
            }
        }

        struct TestHandler: Handler {
            static var collectedOrder: [Int] = []

            func handle() -> String {
                "Hello World"
            }

            var metadata: Metadata {
                Guarded(by: MetadataGuard(order: 6))
                ResetGuards()
                Guarded(by: MetadataGuard(order: 7))
            }
        }

        MetadataGuard.metadataGuardExpectation = expectation(description: "Metadata Guard executed")
        MetadataGuard.metadataGuardExpectation?.expectedFulfillmentCount = 3
        ModifierGuard.modifierGuardExpectation = expectation(description: "Modifier Guard executed")
        ModifierGuard.modifierGuardExpectation?.expectedFulfillmentCount = 1

        let handler = TestHandler()
            .guard(ModifierGuard(order: 1))
            .metadata(TestHandler.Guarded(by: MetadataGuard(order: 2)))
            .resetGuards()
            .metadata {
                TestHandler.Guarded(by: MetadataGuard(order: 3))
                TestHandler.Guarded(by: MetadataGuard(order: 4))
            }
            .guard(ModifierGuard(order: 5))

        let exporter = MockExporter<String>()
        app.registerExporter(exporter: exporter)

        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)

        handler.accept(visitor)
        let context = visitor.currentNode.export()

        modelBuilder.finishedRegistration()

        let response = exporter.request(on: 0, request: "Example Request", with: app)

        try XCTCheckResponse(
            try XCTUnwrap(response.typed(String.self)),
            content: "Hello World"
        )

        XCTAssertEqual(TestHandler.collectedOrder, [3, 4, 5, 7])

        waitForExpectations(timeout: 0)
    }
}
