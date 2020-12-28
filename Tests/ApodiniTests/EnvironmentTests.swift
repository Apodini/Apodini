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
        let component = BirdComponent()
        let request = MockRequest.createRequest(on: component, running: app.eventLoopGroup.next())

        let response: String = request.enterRequestContext(with: component) { component in
            component.handle()
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
