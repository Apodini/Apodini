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

    override func setUpWithError() throws {
        try super.setUpWithError()
        EnvironmentValues.shared = EnvironmentValues()
    }

    func makeResponse<C: Component>(for component: C,
                                    with keyPath: WritableKeyPath<EnvironmentValues, BirdFacts>? = nil,
                                    of environmentValue: BirdFacts? = nil) throws -> Response where C.Response == String {
        let request = Request(application: app, on: app.eventLoopGroup.next())
        let restRequest = RESTRequest(request) { _ in
            nil
        }

        var component = component
        if let keyPath = keyPath,
           let value = environmentValue {
            component = component.withEnvironment(value, for: keyPath)
        }
        return try restRequest
            .enterRequestContext(with: component) { component in
                component
                    .handle()
                    .encodeResponse(for: request)
            }
            .wait()
    }
    
    func testEnvironmentInjection() throws {
        let response = try makeResponse(for: BirdComponent())
        
        let birdFacts = BirdFacts()
        
        let responseData = try XCTUnwrap(response.body.data)
        let responseString = String(decoding: responseData, as: UTF8.self)
        EnvironmentValues.shared.birdFacts = birdFacts
        XCTAssert(responseString == birdFacts.someFact)
    }
    
    func testUpdateEnvironmentValue() throws {
        let birdFacts = BirdFacts()
        let newFact = "Until humans, the Dodo had no predators"
        birdFacts.dodoFact = newFact

        EnvironmentValues.shared.birdFacts = birdFacts
        let injectedValue = EnvironmentValues.shared[keyPath: \EnvironmentValues.birdFacts]
            
        XCTAssert(injectedValue.dodoFact == newFact)
    }

    func testShouldAccessDynamicEnvironmentValueFirst() throws {
        let staticBirdFacts = BirdFacts()

        let dynamicBirdFacts = BirdFacts()
        let dynamicFact = "Until humans, the Dodo had no predators"
        dynamicBirdFacts.someFact = dynamicFact

        // inject the static value via the shared object
        EnvironmentValues.shared.birdFacts = staticBirdFacts
        // inject the dynamic value via the .withEnvironment
        let response = try makeResponse(for: BirdComponent(), with: \EnvironmentValues.birdFacts, of: dynamicBirdFacts)

        let responseData = try XCTUnwrap(response.body.data)
        let responseString = String(decoding: responseData, as: UTF8.self)

        XCTAssertEqual(responseString, dynamicFact)
    }

    func testShouldAccessStaticIfNoDynamicAvailable() throws {
        let staticBirdFacts = BirdFacts()
        let staticFact = "Until humans, the Dodo had no predators"
        staticBirdFacts.someFact = staticFact

        // inject the static value via the shared object
        EnvironmentValues.shared.birdFacts = staticBirdFacts

        let response = try makeResponse(for: BirdComponent())

        let responseData = try XCTUnwrap(response.body.data)
        let responseString = String(decoding: responseData, as: UTF8.self)

        XCTAssertEqual(responseString, staticBirdFacts.someFact)
    }

    func testShouldReturnDefaultIfNoEnvironment() throws {
        let response = try makeResponse(for: BirdComponent())

        let responseData = try XCTUnwrap(response.body.data)
        let responseString = String(decoding: responseData, as: UTF8.self)

        XCTAssertEqual(responseString, BirdFacts().someFact)
    }
}

class BirdFacts {
    var someFact = "Did you know that Apodinae are a subfamily of swifts?"
    
    var dodoFact = "The Dodo lived on the Island of Mauritius"
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
