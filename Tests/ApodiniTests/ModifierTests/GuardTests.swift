//
//  GuardTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

import XCTest
import XCTVapor
import protocol Fluent.Database
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
                RESTInterfaceExporter()
            }
        }
        
        TestWebService.main(app: app)
        
        
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
                RESTInterfaceExporter()
            }
        }
        
        TestWebService.main(app: app)
        
        
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
                RESTInterfaceExporter()
            }
        }
        
        TestWebService.main(app: app)
        
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
            func check() {
                guard let guardExpectation = GuardTests.guardExpectation else {
                    fatalError("The test expectation must be set before testing `TestGuard`")
                }
                guardExpectation.fulfill()
            }
        }
        
        GuardTests.guardExpectation = self.expectation(description: "Guard is executed")
        GuardTests.guardExpectation?.expectedFulfillmentCount = 2
        
        struct TestWebService: WebService {
            var content: some Component {
                Group {
                    Group {
                        Text("Hello")
                            .guard(TestSyncGuard())
                    }.guard(TestSyncGuard())
                }.guard(TestSyncGuard())
                    .resetGuards()
            }

            var configuration: Configuration {
                RESTInterfaceExporter()
            }
        }
        
        TestWebService.main(app: app)
        
        
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
    
    func testResetGuardOnly() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hello")
                    .resetGuards()
            }

            var configuration: Configuration {
                RESTInterfaceExporter()
            }
        }
        
        TestWebService.main(app: app)
        
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
                RESTInterfaceExporter()
            }
        }
        
        TestWebService.main(app: app)
        
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
                RESTInterfaceExporter()
            }
        }
        
        TestWebService.main(app: app)
        
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
    
    func testAllActiveGuardsFunction() {
        struct ThrowAwayComponent: Component {
            var content: some Component {
                EmptyComponent()
            }
        }
        
        func getResetGuard() -> LazyGuard {
            let throwAwayComponent = ThrowAwayComponent()
            return throwAwayComponent.resetGuards().guard
        }
        
        struct TestSyncGuard: SyncGuard, Equatable {
            let id = UUID()
            
            func check() {}
        }
        
        let guards: [LazyGuard] = [ { AnyGuard(TestSyncGuard()) }, { AnyGuard(TestSyncGuard()) }]
        XCTAssertEqual(guards.allActiveGuards.count, 2)
        guards.allActiveGuards.forEach {
            XCTAssertEqual($0().guardType, ObjectIdentifier(TestSyncGuard.self))
        }
        
        let resettedGuards: [LazyGuard] = [ { AnyGuard(TestSyncGuard()) }, { AnyGuard(TestSyncGuard()) }, getResetGuard()]
        XCTAssertEqual(resettedGuards.allActiveGuards.count, 0)
        
        
        let onlyOneGuard: [LazyGuard] = [ { AnyGuard(TestSyncGuard()) }, getResetGuard(), { AnyGuard(TestSyncGuard()) }]
        XCTAssertEqual(onlyOneGuard.allActiveGuards.count, 1)
        onlyOneGuard.allActiveGuards.forEach {
            XCTAssertEqual($0().guardType, ObjectIdentifier(TestSyncGuard.self))
        }
    }
}
