import Foundation
import XCTest
import NIO
import Vapor
@testable import Apodini
@testable import ApodiniDatabase
// swiftlint:disable all
final class DatabaseHandlerTests: ApodiniTests {

    func testCreateHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird.save(on: self.app.db).map({ _ in
            bird
        }).wait()
        XCTAssertNotNil(dbBird.id)
        
        let creationHandler = Create<Bird>()
        
        let request = MockRequest.createRequest(on: creationHandler, running: app.eventLoopGroup.next(), queuedParameters: bird)
        let response = request.enterRequestContext(with: creationHandler, executing: { component in
            component.handle()
        })
        XCTAssertNotNil(response)
        XCTAssert(response == bird)
        
        let foundBird = try Bird.find(dbBird.id, on: app.db).wait()
        XCTAssertNotNil(foundBird)
        XCTAssertEqual(dbBird, foundBird)
    }
    
    func testReadHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird.save(on: self.app.db).map({ _ in
            bird
        }).wait()
        XCTAssertNotNil(dbBird.id)
        
        let readHandler = Read<Bird>()
        let endpoint = readHandler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        let requestHandler = endpoint.createRequestHandler(for: exporter)

        let uri = URI("http://example.de/test/bird?name=Mockingbird")
        let request = Vapor.Request(
                application: app,
                method: .GET,
                url: uri,
                on: app.eventLoopGroup.next()
        )
        request.parameters.set("name", to: "Mockingbird")
        
        let result = try requestHandler(request: request).wait()
        guard case let .final(responseValue) = result else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        let response = try XCTUnwrap(responseValue.value as? String)
        
        let queryBuilder = QueryBuilder(
            type: Bird.self,
            parameters: [
                Bird.fieldKey(for: "name"): "Mockingbird"
            ]
        )
        //As Eventloops are currently not working, only the queryBuilder is tested right now.
        XCTAssertEqual(response, queryBuilder.debugDescription)
    }
    
    func testUpdateHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird.save(on: self.app.db).map({ _ in
            bird
        }).wait()
        XCTAssertNotNil(dbBird.id)
        
        let updatedBird = Bird(name: "FooBird", age: 25)
        
        let handler = Update<Bird>()
        let endpoint = handler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        let requestHandler = endpoint.createRequestHandler(for: exporter)

        let bodyData = ByteBuffer(data: try JSONEncoder().encode(updatedBird))

        let uri = URI("http://example.de/test/id")
        let request = Vapor.Request(
                application: app,
                method: .PUT,
                url: uri,
                collectedBody: bodyData,
                on: app.eventLoopGroup.next()
        )
        guard let birdId = dbBird.id else {
            return
        }
        request.parameters.set(":\(handler.idParameter.id)", to: "\(birdId)")
        
        let result = try requestHandler(request: request)
                .wait()
        guard case let .final(responseValue) = result else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        let response = try XCTUnwrap(responseValue.value as? String)
        XCTAssert(response == "success")
        
        let newBird = try Bird.find(dbBird.id, on: self.app.db).wait()

        XCTAssertNotNil(newBird)
        XCTAssert(newBird!.name == updatedBird.name, newBird.debugDescription)
        XCTAssert(newBird!.age == 25)
        
    }
    
    func testDeleteHandler() throws {
        let bird = Bird(name: "Mockingbird", age: 20)
        let dbBird = try bird.save(on: self.app.db).map({ _ in
            bird
        }).wait()
        XCTAssertNotNil(dbBird.id)
        
        let handler = Delete<Bird>()
        let endpoint = handler.mockEndpoint()

        let exporter = RESTInterfaceExporter(app)
        let requestHandler = endpoint.createRequestHandler(for: exporter)

        let uri = URI("http://example.de/test/id")
        let request = Vapor.Request(
                application: app,
                method: .PUT,
                url: uri,
                on: app.eventLoopGroup.next()
        )
        request.parameters.set(":\(handler.idParameter.id)", to: "\(dbBird.id!)")
        
        let result = try requestHandler(request: request)
                .wait()
        guard case let .final(responseValue) = result else {
            XCTFail("Expected return value to be wrapped in Action.final by default")
            return
        }
        
        let response = try XCTUnwrap(responseValue.value as? String)
        XCTAssertEqual(response, String(HTTPStatus.ok.code))
        let deletedBird = try Bird.find(dbBird.id!, on: app.db).wait()
        XCTAssertNil(deletedBird)
    }
}
// swiftlint:enable all
