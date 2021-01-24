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
        let handler = BirdHandler()
        let request = MockRequest.createRequest(on: handler, running: app.eventLoopGroup.next())

        let response: String = request.enterRequestContext(with: handler) { handler in
            handler.handle()
        }

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

        struct Keys: KeyChain {
            var bird: BirdFacts
        }

        let birdFacts = BirdFacts()
        EnvironmentObject(birdFacts, \Keys.bird).configure(app)

        let handler = AnotherBirdHandler()
        let request = MockRequest.createRequest(on: handler, running: app.eventLoopGroup.next())

        let response: String = request.enterRequestContext(with: handler) { handler in
            handler.handle()
        }

        XCTAssertEqual(response, birdFacts.dodoFact)
    }

    func testDuplicateEnvironmentObjectInjection() throws {
        struct Keys: KeyChain {
            var bird: BirdFacts
        }

        let birdFacts = BirdFacts()
        let birdFacts2 = BirdFacts()
        birdFacts2.someFact = ""

        EnvironmentObject(birdFacts, \Keys.bird).configure(app)
        EnvironmentObject(birdFacts2, \Keys.bird).configure(app)

        XCTAssertEqual(birdFacts2.someFact, Environment(\Keys.bird).wrappedValue.someFact)
    }

    func testUpdateEnvironmentValue() throws {
        let birdFacts = BirdFacts()
        let newFact = "Until humans, the Dodo had no predators"
        birdFacts.dodoFact = newFact

        app.birdFacts = birdFacts
        let injectedValue = app![keyPath: \Application.birdFacts]

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
        app.birdFacts = staticBirdFacts
        // inject the dynamic value via the .withEnvironment
        let response: String = request.enterRequestContext(with: handler) { handler in
            handler
                .environment(dynamicBirdFacts, for: \Application.birdFacts)
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
        app.birdFacts = staticBirdFacts

        let response: String = request.enterRequestContext(with: handler) { handler in
            handler.handle()
        }

        XCTAssertEqual(response, staticBirdFacts.someFact)
    }

    func testShouldReturnDefaultIfNoEnvironment() throws {
        let handler = BirdHandler()
        app.birdFacts = BirdFacts() // Resets value
        let request = MockRequest.createRequest(on: handler, running: app.eventLoopGroup.next())

        let response: String = request.enterRequestContext(with: handler) { handler in
            handler.handle()
        }

        XCTAssertEqual(response, BirdFacts().someFact)
    }

    func testCustomEnvironment() throws {
        XCTAssertRuntimeFailure(self.app.storage.get(\KeyStore.test))

        app.storage.set(\KeyStore.test, to: "Bird")
        XCTAssert(app.storage.get(\KeyStore.test) == "Bird")
    }

    func testAccessApplicationEnvironment() {
        XCTAssert(Environment(\.eventLoopGroup).wrappedValue === app.eventLoopGroup)
    }

    func testFaillingApplicationEnvironmentAccess() {
        AppStorage.app = nil
        XCTAssertRuntimeFailure(Environment(\.apns).wrappedValue,
                                "Key path not found. The web service wasn't setup correctly")
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
        set { BirdFactsEnvironmentKey.defaultValue  = newValue }
    }
}

struct KeyStore: KeyChain {
    var test: String
}
