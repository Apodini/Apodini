import Foundation
import XCTest
import NIO
import Vapor
import Fluent
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

    func result(_ value: String) throws -> String {
        try XCTUnwrap(value)
    }
}
