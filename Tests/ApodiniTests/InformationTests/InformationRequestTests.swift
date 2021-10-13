//
//  InformationRequestTests.swift
//  
//
//  Created by Paul Schmiedmayer on 6/16/21.
//

@testable import Apodini
@testable import ApodiniREST
import XCTApodiniHTTP
import Vapor


final class InformationRequestTests: XCTApodiniHTTPTest {
    func testInformationRequestWithRESTExporter() throws {
        struct InformationHandler: Handler {
            let testExpectations: (Set<AnyInformation>) throws -> Void
            
            
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
        
        
        func testHeaders(_ header: [(String, String)], expectations: @escaping (Set<AnyInformation>) throws -> Void) throws {
            try XCTHTTPCheck(InformationHandler(testExpectations: expectations)) {
                HTTPCheck(HTTPRequest(headers: header)) { response in
                    let response = try response.decodeBody(Int.self)
                    XCTAssertEqual(response, header.count)
                }
            }
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
