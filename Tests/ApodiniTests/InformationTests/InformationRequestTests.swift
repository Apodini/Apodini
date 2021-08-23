//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
@testable import ApodiniREST
import ApodiniLoggingSupport
import XCTApodini
import Vapor

final class InformationRequestTests: XCTApodiniTest {
    func testInformationRequestWithRESTExporter() throws {
        struct InformationHandler: Handler {
            let testExpectations: (InformationSet) throws -> Void
            
            
            @Apodini.Environment(\.connection) var connection: Connection
            
            
            func handle() -> Int {
                do {
                    let info = connection.information
                    try testExpectations(info)
                } catch {
                    XCTFail(error.localizedDescription)
                }
                return connection.information.count
            }
        }
        
        func testHeaders(_ header: [(String, String)], expectations: @escaping (InformationSet) throws -> Void) throws {
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
            
            let countLoggingMetadataInformation = firstRequest
                .information
                .reduce(into: 0) { partialResult, info in
                    if (info as? LoggingMetadataInformation) != nil {
                        partialResult += 1
                    }
                }
            
            let numberOfHeaders: Int = try XCTUnwrap(
                try context.handle(request: firstRequest)
                    .wait()
                    .typed(Int.self)?
                    .content
            )
            
            XCTAssertEqual(numberOfHeaders - countLoggingMetadataInformation, header.count)
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
            let test: String = try XCTUnwrap(information[httpHeader: "Test"])
            XCTAssertEqual(test, "ATest")
        }
    }
}
