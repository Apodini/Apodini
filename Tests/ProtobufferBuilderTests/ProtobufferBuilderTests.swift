import XCTest
@testable import Apodini
import ProtobufferBuilder

final class ProtobufferBuilderTests: XCTestCase {}

// MARK: - Test Components

extension ProtobufferBuilderTests {
    #warning("TODO")
}

// MARK: - Test Misc

extension ProtobufferBuilderTests {
    func testGenericPolymorphism() {
        XCTAssertFalse(Array<Any>.self == Array<Int>.self)
    }
}
