//
//  CustomComponentTest.swift
//
//
//  Created by Paul Schmiedmayer on 6/27/20.
//

@testable import Apodini
@testable import ApodiniVaporSupport
@testable import ApodiniDatabase
@testable import ApodiniREST
import XCTVapor
import XCTApodini


final class CustomComponentTests: ApodiniTests {
    struct AddBirdsHandler: Handler {
        @Apodini.Environment(\.database)
        var database: Database

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
        let bird = Bird(name: "Hummingbird", age: 2)
        
        try XCTCheckHandler(
            AddBirdsHandler(),
            application: self.app,
            request: MockExporterRequest(on: self.app.eventLoopGroup.next()) {
                UnnamedParameter(bird)
            },
            content: [bird1, bird2, bird]
        )
    }
    
    func testComponentRegistration() throws {
        struct TestWebService: WebService {
            var content: some Component {
                AddBirdsHandler()
            }

            var configuration: Configuration {
                ExporterConfiguration()
                    .exporter(RESTInterfaceExporter.self)
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
