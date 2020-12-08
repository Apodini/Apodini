//
//  EnvironmentTests.swift
//  
//
//  Created by Alexander Collins on 08.12.20.
//

import XCTest
import Vapor
@testable import Apodini

final class EnvironmentTests: ApodiniTests {
    struct BirdComponent: Component {
        @Apodini.Environment(\.birdFacts) var birdFacts: BirdFacts
        
        func handle() -> String {
            birdFacts.someFact
        }
    }
    
    func testEnvironmentInjection() throws {
        let request = Request(application: app, on: app.eventLoopGroup.next())
        
        let response = try request
            .enterRequestContext(with: BirdComponent(), using: RESTSemanticModelBuilder(app)) { component in
                component.handle().encodeResponse(for: request)
            }
            .wait()
        
        let birdFacts = BirdFacts()
        
        let responseData = try XCTUnwrap(response.body.data)
        let responseString = String(decoding: responseData, as: UTF8.self)
        
        XCTAssert(responseString == birdFacts.someFact)
    }
}

struct BirdFacts {
    var someFact: String {
        "Did you know that Apodinae are a subfamily of swifts?"
    }
}

enum BirdFactsEnvironmentKey: EnvironmentKey {
    static var defaultValue = BirdFacts()
}

extension EnvironmentValues {
    var birdFacts: BirdFacts {
        get { self[BirdFactsEnvironmentKey.self] }
        set { self[BirdFactsEnvironmentKey.self] = newValue }
    }
}
