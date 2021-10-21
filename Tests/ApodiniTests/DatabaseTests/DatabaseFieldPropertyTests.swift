//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import XCTest
@_implementationOnly import Runtime
@testable import Apodini
@testable import ApodiniDatabase


final class DatabaseFieldPropertyTests: ApodiniTests {
    func testFieldPropertyVisitable() {
        let bird = Bird(name: "MockingBird", age: 25)
        let result = bird.$name.accept(ConcreteTypeVisitor())
        XCTAssert(result.description.contains("MockingBird"), result.description)
    }
    
    func testIDPropertyVisitable() {
        let bird = Bird(name: "MockingBird", age: 25)
        let uuid = UUID()
        bird.id = uuid
        let result = bird.$id.accept(ConcreteIDPropertyVisitor())
        XCTAssert(result.description == "Optional(\(uuid.uuidString))", result.description)
    }
    
    func testFieldPropertyUpdatable() throws {
        let bird = Bird(name: "MockingBird", age: 25)
        let newValueContainer: TypeContainer = .string("FooBird")
        XCTAssertNoThrow(try bird.$name.accept(ConcreteUpdatableFieldPropertyVisitor(updater: newValueContainer)))
        XCTAssert(bird.name == "FooBird")
    }
    
    // TODO why is this here? --> remove!
    func result(_ value: String) throws -> String {
        try XCTUnwrap(value)
    }
}
