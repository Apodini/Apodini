//
//  GRPCServiceTests.swift
//  
//
//  Created by Moritz Schüll on 21.12.20.
//

import XCTest
@testable import Apodini

final class GRPCServiceTests: ApodiniTests {
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        app.storage[IntegerWidthConfiguration.StorageKey] = .native
    }
    
    func testWebService<S: WebService>(_ type: S.Type, path: String) throws {
        let app = Application()
        S.main(app: app)
        defer { app.shutdown() }
        
        try app.vapor.app.test(.POST, path, headers: ["content-type": GRPCService.grpcproto.description]) { res in
            XCTAssertGreaterThanOrEqual(res.status.code, 200)
            XCTAssertLessThan(res.status.code, 300)
        }
    }
}

extension GRPCServiceTests {
    func testWebServiceHelloWorld() throws {
        struct WebService: Apodini.WebService {
            var content: some Component {
                HelloWorld()
                    .serviceName("service")
                    .rpcName("method")
            }
            
            var configuration: Configuration {
                IntegerWidthConfiguration.sixtyFour
            }
        }
        
        struct HelloWorld: Handler {
            func handle() -> String {
                "Hello, World!"
            }
        }
        
        try testWebService(WebService.self, path: "service/method")
    }
}
