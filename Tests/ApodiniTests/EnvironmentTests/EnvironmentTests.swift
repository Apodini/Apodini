//
//  EnvironmentTests.swift
//
//
//  Created by Alexander Collins on 08.12.20.
//

import XCTest
import XCTApodini
@testable import Apodini

final class EnvironmentTests: ApodiniTests {
    struct BirdHandler: Handler {
        @Apodini.Environment(\.birdFacts) var birdFacts: BirdFacts

        func handle() -> String {
            birdFacts.someFact
        }
    }

    func testEnvironmentInjection() throws {
        let response = try XCTUnwrap(mockQuery(handler: BirdHandler(), value: String.self, app: app))

        let birdFacts = BirdFacts()

        app.birdFacts = birdFacts
        XCTAssert(response == birdFacts.someFact)
    }

    func testEnvironmentObjectInjection() throws {
        struct AnotherBirdHandler: Handler {
            @Apodini.Environment(\Keys.bird) var bird: BirdFacts

            func handle() -> String {
                bird.dodoFact = "Until humans, the Dodo had no predators"
                return bird.dodoFact
            }
        }

        struct Keys: EnvironmentAccessible {
            var bird: BirdFacts
        }

        let birdFacts = BirdFacts()
        EnvironmentValue(birdFacts, \Keys.bird).configure(app)

        let response = try XCTUnwrap(mockQuery(handler: AnotherBirdHandler(), value: String.self, app: app))

        XCTAssertEqual(response, birdFacts.dodoFact)
    }

    func testDuplicateEnvironmentObjectInjection() throws {
        struct Keys: EnvironmentAccessible {
            var bird: BirdFacts
        }

        let birdFacts = BirdFacts()
        let birdFacts2 = BirdFacts()
        birdFacts2.someFact = ""

        EnvironmentValue(birdFacts, \Keys.bird).configure(app)
        EnvironmentValue(birdFacts2, \Keys.bird).configure(app)
        
        var environment = Environment(\Keys.bird)
        environment.inject(app: app)
        environment.activate()

        XCTAssertEqual(birdFacts2.someFact, environment.wrappedValue.someFact)
    }

    func testUpdateEnvironmentValue() throws {
        let birdFacts = BirdFacts()
        let newFact = "Until humans, the Dodo had no predators"
        birdFacts.dodoFact = newFact

        app.birdFacts = birdFacts
        
        var environment = Environment(\Application.birdFacts)
        environment.inject(app: app)
        environment.activate()
        let injectedValue = environment.wrappedValue

        XCTAssert(injectedValue.dodoFact == newFact)
    }

    func testShouldAccessDynamicEnvironmentValueFirst() throws {
        var handler = BirdHandler()
        let staticBirdFacts = BirdFacts()

        let dynamicBirdFacts = BirdFacts()
        let dynamicFact = "Until humans, the Dodo had no predators"
        dynamicBirdFacts.someFact = dynamicFact
        
        handler = handler
            .inject(app: app)
            .environment(dynamicBirdFacts, for: \Application.birdFacts)
        
        activate(&handler)

        let request = MockRequest.createRequest(on: handler, running: app.eventLoopGroup.next())

        // inject the static value via the shared object
        app.birdFacts = staticBirdFacts
        // inject the dynamic value via the .withEnvironment
        let response: String = try request.enterRequestContext(with: handler) { handler in
            handler
                .handle()
        }

        XCTAssertEqual(response, dynamicFact)
    }

    func testShouldAccessStaticIfNoDynamicAvailable() throws {
        let staticBirdFacts = BirdFacts()
        let staticFact = "Until humans, the Dodo had no predators"
        staticBirdFacts.someFact = staticFact

        // inject the static value via the shared object
        app.birdFacts = staticBirdFacts

        let response = try XCTUnwrap(mockQuery(handler: BirdHandler(), value: String.self, app: app))

        XCTAssertEqual(response, staticBirdFacts.someFact)
    }

    func testShouldReturnDefaultIfNoEnvironment() throws {
        app.birdFacts = BirdFacts() // Resets value
     
        let response = try XCTUnwrap(mockQuery(handler: BirdHandler(), value: String.self, app: app))

        XCTAssertEqual(response, BirdFacts().someFact)
    }

    func testCustomEnvironment() throws {
        XCTAssertNil(self.app.storage.get(\KeyStore.test))

        app.storage.set(\KeyStore.test, to: "Bird")
        XCTAssert(app.storage.get(\KeyStore.test) == "Bird")
    }

    func testFaillingApplicationEnvironmentAccess() {
        XCTAssertRuntimeFailure(Environment(\.threadPool).wrappedValue,
                                "The Application instance wasn't injected correctly.")
        
        var environment = Environment(\.locks)
        environment.activate()
        XCTAssertRuntimeFailure(environment.wrappedValue,
                                "The wrapped value was accessed before it was activated.")
    }
}

class BirdFacts {
    var someFact = "Did you know that Apodinae are a subfamily of swifts?"

    var dodoFact = "The Dodo lived on the Island of Mauritius"
}

enum BirdFactsEnvironmentKey: StorageKey {
    typealias Value = BirdFacts
    static var defaultValue = BirdFacts()
}

extension Application {
    var birdFacts: BirdFacts {
        get { BirdFactsEnvironmentKey.defaultValue }
        set { BirdFactsEnvironmentKey.defaultValue = newValue }
    }
}

struct KeyStore: EnvironmentAccessible {
    var test: String
}
