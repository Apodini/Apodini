//
//  WebService.swift
//  
//
//  Created by Paul Schmiedmayer on 1/2/21.
//

import XCTVapor
@testable import Apodini


final class WebServiceTests: ApodiniTests {
    func testWebServiceCreateApplication() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Text("Hello World!")
            }
        }
        
        let application = try TestWebService.createApplication()
        application.shutdown()
    }
}
