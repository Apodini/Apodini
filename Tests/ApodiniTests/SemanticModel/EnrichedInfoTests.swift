//
//  Created by Lorena Schlesinger on 1/15/21.
//

import XCTest
@_implementationOnly import Runtime

@testable import Apodini

class EnrichedInfoTests: ApodiniTests {

    func testCardinality(_ lhs: Any.Type, _ rhs: Any.Type, isEqual: Bool) throws {
        let keyPath = \Node<EnrichedInfo>.value.cardinality

        if isEqual {
            XCTAssertEqual(
                try EnrichedInfo.node(lhs).edited(handleArray)?.edited(handleDictionary)?[keyPath: keyPath],
                try EnrichedInfo.node(rhs).edited(handleArray)?.edited(handleDictionary)?[keyPath: keyPath]
            )
        } else {
            XCTAssertNotEqual(
                try EnrichedInfo.node(lhs).edited(handleArray)?.edited(handleDictionary)?[keyPath: keyPath],
                try EnrichedInfo.node(rhs).edited(handleArray)?.edited(handleDictionary)?[keyPath: keyPath]
            )
        }
    }

    func testEnrichedInfo(_ lhs: Any.Type, _ rhs: Any.Type, isEqual: Bool) throws {
        if isEqual {
            XCTAssertEqual(
                try EnrichedInfo.node(lhs).edited(handleArray)?.edited(handleDictionary)?.value,
                try EnrichedInfo.node(rhs).edited(handleArray)?.edited(handleDictionary)?.value
            )
        } else {
            XCTAssertNotEqual(
                try EnrichedInfo.node(lhs).edited(handleArray)?.edited(handleDictionary)?.value,
                try EnrichedInfo.node(rhs).edited(handleArray)?.edited(handleDictionary)?.value
            )
        }
    }

    func testCardinalityIsEquatable() throws {
        try testCardinality(String.self, Int.self, isEqual: true)
        try testCardinality(Array<Int>.self, Array<String>.self, isEqual: true)
        try testCardinality(Dictionary<Int, String>.self, Dictionary<Int, String>.self, isEqual: true)
        try testCardinality(Array<String>.self, Dictionary<Int, String>.self, isEqual: false)
        try testCardinality(String.self, Array<Int>.self, isEqual: false)
        try testCardinality(String.self, Dictionary<Int, String>.self, isEqual: false)
    }

    func testEnrichedInfoIsEquatable() throws {
        try testEnrichedInfo(String.self, Int.self, isEqual: false)
        try testEnrichedInfo(Array<Int>.self, Array<Int>.self, isEqual: true)
        try testEnrichedInfo(Array<Int>.self, Array<String>.self, isEqual: false)
        try testEnrichedInfo(Dictionary<Int, String>.self, Dictionary<Int, String>.self, isEqual: true)
        try testEnrichedInfo(Array<String>.self, Dictionary<Int, String>.self, isEqual: false)
        try testEnrichedInfo(String.self, Array<Int>.self, isEqual: false)
        try testEnrichedInfo(String.self, Dictionary<Int, String>.self, isEqual: false)
    }
}
