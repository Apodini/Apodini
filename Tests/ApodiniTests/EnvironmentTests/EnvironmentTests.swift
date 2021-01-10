//
//  EnvironmentTests.swift
//  
//
//  Created by Alexander Collins on 08.12.20.
//

import XCTest
import Vapor
import XCTApodini
@testable import Apodini

final class EnvironmentTests: ApodiniTests {
    struct BirdHandler: Handler {
        @Apodini.Environment(\.birdFacts) var birdFacts: BirdFacts
        
        func handle() -> String {
            birdFacts.someFact
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        EnvironmentValues.shared = EnvironmentValues()
    }

    func testEnvironmentInjection() throws {
        let handler = BirdHandler()
        let request = MockRequest.createRequest(on: handler, running: app.eventLoopGroup.next())

        let response: String = request.enterRequestContext(with: handler) { handler in
            handler.handle()
        }

        let birdFacts = BirdFacts()

        EnvironmentValues.shared.birdFacts = birdFacts
        XCTAssert(response == birdFacts.someFact)
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
        let handler = BirdHandler()
        let staticBirdFacts = BirdFacts()

        let dynamicBirdFacts = BirdFacts()
        let dynamicFact = "Until humans, the Dodo had no predators"
        dynamicBirdFacts.someFact = dynamicFact

        let request = MockRequest.createRequest(on: handler, running: app.eventLoopGroup.next())

        // inject the static value via the shared object
        EnvironmentValues.shared.birdFacts = staticBirdFacts
        // inject the dynamic value via the .withEnvironment
        let response: String = request.enterRequestContext(with: handler) { handler in
            handler
                .environment(dynamicBirdFacts, for: \EnvironmentValues.birdFacts)
                .handle()
        }

        XCTAssertEqual(response, dynamicFact)
    }

    func testShouldAccessStaticIfNoDynamicAvailable() throws {
        let handler = BirdHandler()
        let staticBirdFacts = BirdFacts()
        let staticFact = "Until humans, the Dodo had no predators"
        staticBirdFacts.someFact = staticFact

        let request = MockRequest.createRequest(on: handler, running: app.eventLoopGroup.next())

        // inject the static value via the shared object
        EnvironmentValues.shared.birdFacts = staticBirdFacts

        let response: String = request.enterRequestContext(with: handler) { handler in
            handler.handle()
        }

        XCTAssertEqual(response, staticBirdFacts.someFact)
    }

    func testShouldReturnDefaultIfNoEnvironment() throws {
        let handler = BirdHandler()
        let request = MockRequest.createRequest(on: handler, running: app.eventLoopGroup.next())

        let response: String = request.enterRequestContext(with: handler) { handler in
            handler.handle()
        }

        XCTAssertEqual(response, BirdFacts().someFact)
    }
    
    func testCustomEnvironment() throws {
        XCTAssertRuntimeFailure(EnvironmentValues.shared[\KeyStore.test])
        
        EnvironmentValues.shared.values[ObjectIdentifier(\KeyStore.test)] = "Bird"
        XCTAssert(EnvironmentValues.shared[\KeyStore.test] == "Bird")
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

struct KeyStore: ApodiniKeys {
    var test: String
}
