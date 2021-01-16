import Foundation
import XCTest
import NIO
import Vapor
import Fluent
import Runtime
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
        let dbBird = try bird
            .save(on: self.app.db)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        let creationHandler = Create<Bird>()

        let request = MockRequest.createRequest(on: creationHandler, running: app.eventLoopGroup.next(), queuedParameters: bird)
        let response = try request.enterRequestContext(with: creationHandler, executing: { component in
            component.handle()
        }).wait()
        XCTAssert(response == bird)
        
        let foundBird = try Bird.find(response.id, on: app.db).wait()
        XCTAssertNotNil(foundBird)
        XCTAssertEqual(response, foundBird)
    }
    
    func testReadHandler() throws {
        let bird1 = Bird(name: "Mockingbird", age: 20)
        let dbBird1 = try bird1
            .save(on: self.app.db)
            .transform(to: bird1)
            .wait()
        
        let bird2 = Bird(name: "Mockingbird", age: 21)
        let dbBird2 = try bird2
            .save(on: self.app.db)
            .transform(to: bird2)
            .wait()
        XCTAssertNotNil(dbBird1.id)
        XCTAssertNotNil(dbBird2.id)
        
        let readHandler = Read<Bird>()
        let endpoint = readHandler.mockEndpoint()

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
        let dbBird = try bird
            .save(on: self.app.db)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        let parameters: [String: TypeContainer] = [
            "name": TypeContainer(with: "FooBird")
        ]
        
        let handler = Update<Bird>()
        let endpoint = handler.mockEndpoint()

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
        guard let birdId = dbBird.id else {
            XCTFail("Object found in db has no id")
            return
        }
        let idParameter = try pathParameter(for: handler)
        request.parameters.set("\(idParameter.id)", to: "\(birdId)")
        
        let result = try context.handle(request: request).wait()
        
        guard case let .final(responseValue) = result.typed(Bird.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        XCTAssert(responseValue.id == dbBird.id, responseValue.description)
        XCTAssert(responseValue.name == "FooBird", responseValue.description)

        guard let newBird = try Bird.find(dbBird.id, on: self.app.db).wait() else {
            XCTFail("Failed to find updated object")
            return
        }

        XCTAssertNotNil(newBird)
        XCTAssert(newBird == responseValue, newBird.description)
        
        
    }
    
    func testUpdateHandlerWithModel() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.db)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        let updatedBird = Bird(name: "FooBird", age: 25)
        
        let handler = Update<Bird>()
        let endpoint = handler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)

        let bodyData = ByteBuffer(data: try JSONEncoder().encode(updatedBird))

        let uri = URI("http://example.de/test/id")
        let request = Vapor.Request(
                application: vaporApp,
                method: .PUT,
                url: uri,
                collectedBody: bodyData,
                on: app.eventLoopGroup.next()
        )
        guard let birdId = dbBird.id else {
            XCTFail("Object found in db has no id")
            return
        }
        let idParameter = try pathParameter(for: handler)
        request.parameters.set("\(idParameter.id)", to: "\(birdId)")
        
        let result = try context.handle(request: request).wait()
        
        guard case let .final(responseValue) = result.typed(Bird.self) else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        XCTAssert(responseValue.name == updatedBird.name, responseValue.description)
        XCTAssert(responseValue.age == updatedBird.age, responseValue.description)

        guard let newBird = try Bird.find(dbBird.id, on: self.app.db).wait() else {
            XCTFail("Failed to find updated object")
            return
        }

        XCTAssertNotNil(newBird)
        XCTAssert(newBird == responseValue, newBird.description)
    }
    
    func testDeleteHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird
            .save(on: self.app.db)
            .transform(to: bird)
            .wait()
        XCTAssertNotNil(dbBird.id)
        
        let handler = Delete<Bird>()
        let endpoint = handler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        var context = endpoint.createConnectionContext(for: exporter)

        let uri = URI("http://example.de/test/id")
        let request = Vapor.Request(
                application: vaporApp,
                method: .PUT,
                url: uri,
                on: app.eventLoopGroup.next()
        )
        
        guard let birdId = dbBird.id else {
            XCTFail("Object saved in db has no id")
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
        
        let deletedBird = try Bird.find(dbBird.id, on: app.db).wait()
        XCTAssertNil(deletedBird)
    }
}
