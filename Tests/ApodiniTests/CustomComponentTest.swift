//
//  CustomComponentTest.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

@testable import Apodini
import Fluent
import XCTVapor


final class CustomComponentTests: ApodiniTests {
    struct AddatabaseirdsHandler: Handler {
        @Apodini.Environment(\.database)
        var database: Fluent.Database

        @Parameter
        var bird: Bird


        func handle() -> EventLoopFuture<[Bird]> {
            bird.save(on: database)
                .flatMap { _ in
                    Bird.query(on: database)
                        .all()
                }
        }
    }
    
    
    func testComponentCreation() throws {
        let addatabaseird = AddatabaseirdsHandler()
        let endpoint = addatabaseird.mockEndpoint(app: app)

        let bird = Bird(name: "Hummingbird", age: 2)
        let exporter = MockExporter<String>(queued: bird)

        var context = endpoint.createConnectionContext(for: exporter)
        
        let result = try context.handle(request: "Example Request", eventLoop: app.eventLoopGroup.next())
                .wait()
        
        guard case let .final(responseValue) = result.typed([Bird].self) else {
            XCTFail("Expected return value to be wrapped in Response.final by default")
            return
        }
        
        XCTAssertEqual(responseValue.count, 3)
        XCTAssertEqual(responseValue[0], bird1)
        XCTAssertEqual(responseValue[1], bird2)
        XCTAssertEqual(responseValue[2], bird)
    }
    
    func testComponentRegistration() throws {
        struct TestWebService: WebService {
            var content: some Component {
                AddatabaseirdsHandler()
            }
        }
        
        TestWebService.main(app: app)
        
        
        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        
        let bird3 = Bird(name: "Hummingbird", age: 2)
        let birdJSON = try JSONEncoder().encode(bird3)
        let body = ByteBuffer(data: birdJSON)
        
        try app.vapor.app.test(.GET, "/v1/", headers: headers, body: body) { res in
            XCTAssertEqual(res.status, .ok)
            
            struct ResponseContent: Decodable {
                let data: [Bird]
            }
            
            let responseBirds = try res.content.decode(ResponseContent.self).data
            XCTAssertEqual(responseBirds.count, 3)
            XCTAssertEqual(responseBirds[0], bird1)
            XCTAssertEqual(responseBirds[1], bird2)
            XCTAssertEqual(responseBirds[2], bird3)
        }
    }
}
