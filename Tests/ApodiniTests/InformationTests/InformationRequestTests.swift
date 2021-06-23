//
//  InformationRequestTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

@testable import Apodini
@testable import ApodiniREST
import XCTApodini
import Vapor


final class InformationRequestTests: XCTApodiniTest {
    func testInformationRequestWithRESTExporter() throws {
        struct InformationHandler: Handler {
            let testExpectations: (Set<AnyInformation>) throws -> Void
            
            
            @Apodini.Environment(\.connection) var connection: Connection
            
            
            func handle() -> Int {
                do {
                    try testExpectations(connection.information)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                return connection.information.count
            }
        }
        
        func testHeaders(_ header: [(String, String)], expectations: @escaping (Set<AnyInformation>) throws -> Void) throws {
            let handler = InformationHandler(testExpectations: expectations)
            let endpoint = handler.mockEndpoint(app: app)
            
            let exporter = RESTInterfaceExporter(app)
            let context = endpoint.createConnectionContext(for: exporter)
            
            
            let firstRequest = Vapor.Request(
                application: app.vapor.app,
                method: .GET,
                url: URI("https://ase.in.tum.de/schmiedmayer"),
                headers: HTTPHeaders(header),
                on: app.eventLoopGroup.next()
            )
            
            let numberOfHeaders: Int = try XCTUnwrap(
                try context.handle(request: firstRequest)
                    .wait()
                    .typed(Int.self)?
                    .content
            )
            
            XCTAssertEqual(numberOfHeaders, header.count)
        }
        
        
        try testHeaders([("Authorization", "Basic UGF1bFNjaG1pZWRtYXllcjpTdXBlclNlY3JldFBhc3N3b3Jk")]) { information in
            let authorization = try XCTUnwrap(information[Authorization.self])
            XCTAssertNil(authorization.bearerToken)
            XCTAssertEqual(authorization.type, "Basic")
            XCTAssertEqual(authorization.credentials, "UGF1bFNjaG1pZWRtYXllcjpTdXBlclNlY3JldFBhc3N3b3Jk")
            XCTAssertEqual(authorization.basic?.username, "PaulSchmiedmayer")
            XCTAssertEqual(authorization.basic?.password, "SuperSecretPassword")
        }
        
        try testHeaders([("Test", "ATest")]) { information in
            let test = try XCTUnwrap(information["Test"])
            XCTAssertEqual(test, "ATest")
        }
    }
}
