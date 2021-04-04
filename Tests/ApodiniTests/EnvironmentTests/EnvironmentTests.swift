//
//  EnvironmentTests.swift
//
//
//  Created by Alexander Collins on 08.12.20.
//

import XCTest
import XCTApodini
@testable import Apodini
@testable import ApodiniNotifications

final class EnvironmentTests: ApodiniTests {
    struct BirdHandler: Handler {
        @Apodini.Environment(\.birdFacts) var birdFacts: BirdFacts

        func handle() -> String {
            birdFacts.someFact
        }
    }

    func testEnvironmentInjection() throws {
        try XCTCheckHandler(
            BirdHandler(),
            application: self.app,
            content: BirdFacts().someFact
        )
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
        EnvironmentObject(birdFacts, \Keys.bird).configure(app)
        
        try XCTCheckHandler(
            AnotherBirdHandler(),
            application: self.app,
            content: birdFacts.dodoFact
        )
    }

    func testDuplicateEnvironmentObjectInjection() throws {
        struct Keys: EnvironmentAccessible {
            var bird: BirdFacts
        }

        let birdFacts = BirdFacts()
        let birdFacts2 = BirdFacts()
        birdFacts2.someFact = ""

        EnvironmentObject(birdFacts, \Keys.bird).configure(app)
        EnvironmentObject(birdFacts2, \Keys.bird).configure(app)
        
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
        // inject the static value via the shared object
        app.birdFacts = BirdFacts()

        let dynamicBirdFacts = BirdFacts()
        let dynamicFact = "Until humans, the Dodo had no predators"
        dynamicBirdFacts.someFact = dynamicFact
        
        try XCTCheckHandler(
            // inject the dynamic value via the .withEnvironment
            BirdHandler().environment(dynamicBirdFacts, for: \Application.birdFacts),
            application: self.app,
            content: dynamicFact
        )
    }

    func testShouldAccessStaticIfNoDynamicAvailable() throws {
        let staticBirdFacts = BirdFacts()
        let staticFact = "Until humans, the Dodo had no predators"
        staticBirdFacts.someFact = staticFact

        // inject the static value via the shared object
        app.birdFacts = staticBirdFacts

        try XCTCheckHandler(
            BirdHandler(),
            application: self.app,
            content: staticBirdFacts.someFact
        )
    }

    func testShouldReturnDefaultIfNoEnvironment() throws {
        app.birdFacts = BirdFacts() // Resets value
        
        try XCTCheckHandler(
            BirdHandler(),
            application: self.app,
            content: BirdFacts().someFact
        )
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
