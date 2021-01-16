import Foundation
import XCTest
import NIO
import Vapor
import Fluent
import Runtime
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
    
    func testFieldPropertyUpdatable() {
        let bird = Bird(name: "MockingBird", age: 25)
        let newValueContainer: TypeContainer = .string("FooBird")
        let result = bird.$name.accept(ConcreteUpdatableFieldPropertyVisitor(updater: newValueContainer))
        XCTAssert(result == true, bird.description)
        XCTAssert(bird.name == "FooBird", result.description)
    }

    func result(_ value: String) throws -> String {
        try XCTUnwrap(value)
    }
}
