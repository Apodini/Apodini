import Foundation
import XCTest
import NIO
import Vapor
import Fluent
@_implementationOnly import Runtime
@testable import Apodini
@testable import ApodiniDatabase

final class DatabaseHandlerTests: ApodiniTests {
    var vaporApp: Vapor.Application {
        self.app.vapor.app
    }
    
    private func pathParameter(for handler: Any) throws -> Parameter<UUID> {
        let mirror = Mirror(reflecting: handler)
        let parameter = mirror.children.compactMap { $0.value as? Parameter<UUID> }.first
        guard let idParameter = parameter else {
            //No point in continuing if there is no parameter
            fatalError("no idParameter found")
        }
        return idParameter
    }
    
    func testCreateHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let databaseBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(databaseBird.id)
        
        let creationHandler = Create<Bird>()
        
        let response = try XCTUnwrap(mockQuery(component: creationHandler, value: Bird.self, app: app, queued: bird))
        XCTAssert(response == bird)
        
        let foundatabaseird = try Bird.find(response.id, on: app.database).wait()
        XCTAssertNotNil(foundatabaseird)
        XCTAssertEqual(response, foundatabaseird)
    }
    
    func testSingleReadHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let databaseBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        let birdId = try XCTUnwrap(databaseBird.id)
        
        let handler = ReadOne<Bird>()
        let endpoint = handler.mockEndpoint(app: app)
        
        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)
        
        let uri = URI("http://example.de/test/id")
        let request = Vapor.Request(
            application: vaporApp,
            method: .GET,
            url: uri,
            on: app.eventLoopGroup.next()
        )
        
        let idParameter = try pathParameter(for: handler)
        request.parameters.set("\(idParameter.id)", to: "\(birdId)")
        
        let result = try context.handle(request: request).wait()
        guard case let .final(response) = result.typed(Bird.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        XCTAssert(response == databaseBird)
    }
    
    func testReadHandler() throws {
        let bird1 = Bird(name: "Mockingbird", age: 20)
        let databaseBird1 = try bird1
            .save(on: self.app.database)
            .transform(to: bird1)
            .wait()
        
        let bird2 = Bird(name: "Mockingbird", age: 21)
        let databaseBird2 = try bird2
            .save(on: self.app.database)
            .transform(to: bird2)
            .wait()
        XCTAssertNotNil(databaseBird1.id)
        XCTAssertNotNil(databaseBird2.id)
        
        let readHandler = ReadAll<Bird>()
        let endpoint = readHandler.mockEndpoint(app: app)
        
        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)
        
        var uri = URI("http://example.de/test/bird?name=Mockingbird")
        var request = Vapor.Request(
            application: vaporApp,
            method: .GET,
            url: uri,
            on: app.eventLoopGroup.next()
        )
        
        var result = try context.handle(request: request).wait()
        guard case let .final(responseValue) = result.typed([Bird].self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        XCTAssert(responseValue.count == 2)
        XCTAssert(responseValue[0].name == "Mockingbird", responseValue.debugDescription)
        XCTAssert(responseValue[1].name == "Mockingbird", responseValue.debugDescription)
        
        uri = URI("http://example.de/test/bird?name=Mockingbird&age=21")
        request = Vapor.Request(
            application: vaporApp,
            method: .GET,
            url: uri,
            on: app.eventLoopGroup.next()
        )
        result = try context.handle(request: request).wait()
        guard case let .final(value) = result.typed([Bird].self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        XCTAssert(value.count == 1)
        XCTAssert(value[0].age == 21, value.debugDescription)
    }
    
    func testUpdateHandleWithSingleParameter() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let databaseBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(databaseBird.id)
        
        let parameters: [String: TypeContainer] = [
            "name": TypeContainer(with: "FooBird")
        ]
        
        let handler = Update<Bird>()
        let endpoint = handler.mockEndpoint(app: app)
        
        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)
        
        let bodyData = ByteBuffer(data: try JSONEncoder().encode(parameters))
        
        let uri = URI("http://example.de/test/id")
        let request = Vapor.Request(
            application: vaporApp,
            method: .PUT,
            url: uri,
            collectedBody: bodyData,
            on: app.eventLoopGroup.next()
        )
        guard let birdId = databaseBird.id else {
            XCTFail("Object found in database has no id")
            return
        }
        let idParameter = try pathParameter(for: handler)
        request.parameters.set("\(idParameter.id)", to: "\(birdId)")
        
        let result = try context.handle(request: request).wait()
        
        guard case let .final(responseValue) = result.typed(Bird.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        XCTAssert(responseValue.id == databaseBird.id, responseValue.description)
        XCTAssert(responseValue.name == "FooBird", responseValue.description)
        
        guard let newBird = try Bird.find(databaseBird.id, on: self.app.database).wait() else {
            XCTFail("Failed to find updated object")
            return
        }
        
        XCTAssertNotNil(newBird)
        XCTAssert(newBird == responseValue, newBird.description)
    }
    
    func testUpdateHandlerWithModel() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let databaseBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(databaseBird.id)
        
        let updatedatabaseird = Bird(name: "FooBird", age: 25)
        
        let handler = Update<Bird>()
        let endpoint = handler.mockEndpoint(app: app)
        
        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)
        
        let bodyData = ByteBuffer(data: try JSONEncoder().encode(updatedatabaseird))
        
        let uri = URI("http://example.de/test/id")
        let request = Vapor.Request(
            application: vaporApp,
            method: .PUT,
            url: uri,
            collectedBody: bodyData,
            on: app.eventLoopGroup.next()
        )
        guard let birdId = databaseBird.id else {
            XCTFail("Object found in database has no id")
            return
        }
        let idParameter = try pathParameter(for: handler)
        request.parameters.set("\(idParameter.id)", to: "\(birdId)")
        
        let result = try context.handle(request: request).wait()
        
        guard case let .final(responseValue) = result.typed(Bird.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        XCTAssert(responseValue.name == updatedatabaseird.name, responseValue.description)
        XCTAssert(responseValue.age == updatedatabaseird.age, responseValue.description)
        
        guard let newBird = try Bird.find(databaseBird.id, on: self.app.database).wait() else {
            XCTFail("Failed to find updated object")
            return
        }
        
        XCTAssertNotNil(newBird)
        XCTAssert(newBird == responseValue, newBird.description)
    }
    
    func testDeleteHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let databaseBird = try bird
            .save(on: self.app.database)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(databaseBird.id)
        
        let handler = Delete<Bird>()
        let endpoint = handler.mockEndpoint(app: app)
        
        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)
        
        let uri = URI("http://example.de/test/id")
        let request = Vapor.Request(
            application: vaporApp,
            method: .PUT,
            url: uri,
            on: app.eventLoopGroup.next()
        )
        
        guard let birdId = databaseBird.id else {
            XCTFail("Object saved in database has no id")
            return
        }
        
        let idParameter = try pathParameter(for: handler)
        request.parameters.set("\(idParameter.id)", to: "\(birdId)")
        
        let result = try context.handle(request: request).wait()
        guard case let .final(response) = result.typed(UInt.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        
        XCTAssertEqual(response, HTTPStatus.ok.code)
        expectation(description: "database access").isInverted = true
        waitForExpectations(timeout: 10, handler: nil)
        
        let deletedatabaseird = try Bird.find(databaseBird.id, on: app.database).wait()
        XCTAssertNil(deletedatabaseird)
    }
}
