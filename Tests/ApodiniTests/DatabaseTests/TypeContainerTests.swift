//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Foundation
import XCTest
@testable import ApodiniDatabase

final class TypeContainerTests: ApodiniTests {
    func testTypeContainer() throws {
        var typeContainer = TypeContainer(with: Int(-2))
        XCTAssert(typeContainer.debugDescription == String(-2))
        XCTAssert(typeContainer.typed() is Int)
        
        typeContainer = TypeContainer(with: Int8(-2))
        XCTAssert(typeContainer.debugDescription == String(-2))
        XCTAssert(typeContainer.typed() is Int8)
        
        typeContainer = TypeContainer(with: Int16(-2))
        XCTAssert(typeContainer.debugDescription == String(-2))
        XCTAssert(typeContainer.typed() is Int16)
        
        typeContainer = TypeContainer(with: Int32(-2))
        XCTAssert(typeContainer.debugDescription == String(-2))
        XCTAssert(typeContainer.typed() is Int32)
        
        typeContainer = TypeContainer(with: Int64(-2))
        XCTAssert(typeContainer.debugDescription == String(-2))
        XCTAssert(typeContainer.typed() is Int64)
        
        typeContainer = TypeContainer(with: UInt(2))
        XCTAssert(typeContainer.debugDescription == String(2))
        XCTAssert(typeContainer.typed() is UInt)
        
        typeContainer = TypeContainer(with: UInt8(2))
        XCTAssert(typeContainer.debugDescription == String(2))
        XCTAssert(typeContainer.typed() is UInt8)
        
        typeContainer = TypeContainer(with: UInt16(2))
        XCTAssert(typeContainer.debugDescription == String(2))
        XCTAssert(typeContainer.typed() is UInt16)
        
        typeContainer = TypeContainer(with: UInt32(2))
        XCTAssert(typeContainer.debugDescription == String(2))
        XCTAssert(typeContainer.typed() is UInt32)
        
        typeContainer = TypeContainer(with: UInt64(2))
        XCTAssert(typeContainer.debugDescription == String(2))
        XCTAssert(typeContainer.typed() is UInt64)
        
        typeContainer = TypeContainer(with: 2.2)
        XCTAssert(typeContainer.debugDescription == String(2.2))
        XCTAssert(typeContainer.typed() is Double)
        
        typeContainer = TypeContainer(with: Float(2.2))
        XCTAssert(typeContainer.debugDescription == String(2.2))
        XCTAssert(typeContainer.typed() is Float)
        
        let uuid = UUID()
        typeContainer = TypeContainer(with: uuid)
        XCTAssert(typeContainer.debugDescription == uuid.uuidString)
        XCTAssert(typeContainer.typed() is UUID)
        
        typeContainer = TypeContainer(with: true)
        XCTAssert(typeContainer.debugDescription == "true")
        XCTAssert(typeContainer.typed() is Bool)
        
        typeContainer = TypeContainer(with: "HelloWorld")
        XCTAssert(typeContainer.debugDescription == "HelloWorld", typeContainer.debugDescription)
        XCTAssert(typeContainer.typed() is String)
    }
    
    func testTypeContainerIntegerCoding() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        var typeContainer = TypeContainer(with: Int(-2))
        var encodedContainer = try encoder.encode(typeContainer)
        var decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        _ = decodedContainer
        XCTAssert(typeContainer.typed() is Int)
        
        typeContainer = TypeContainer(with: Int8(-2))
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(typeContainer.typed() is Int8)
        
        typeContainer = TypeContainer(with: Int16(-2))
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(typeContainer.typed() is Int16)
        
        typeContainer = TypeContainer(with: Int32(-2))
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(typeContainer.typed() is Int32)
        
        typeContainer = TypeContainer(with: Int64(-2))
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(typeContainer.typed() is Int64)
        
        typeContainer = TypeContainer(with: UInt(2))
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(typeContainer.typed() is UInt)
        
        typeContainer = TypeContainer(with: UInt8(2))
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(typeContainer.typed() is UInt8)
        
        typeContainer = TypeContainer(with: UInt16(2))
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(typeContainer.typed() is UInt16)
        
        typeContainer = TypeContainer(with: UInt32(2))
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(typeContainer.typed() is UInt32)
        
        typeContainer = TypeContainer(with: UInt64(2))
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(typeContainer.typed() is UInt64)
    }
    
    func testTypeContainerOtherTypesCoding() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let uuid = UUID()
        var typeContainer = TypeContainer(with: uuid)
        var encodedContainer = try encoder.encode(typeContainer)
        var decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(decodedContainer.typed() is UUID)
        
        typeContainer = TypeContainer(with: true)
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(decodedContainer.typed() is Bool)
        
        typeContainer = TypeContainer(with: "HelloWorld")
        encodedContainer = try encoder.encode(typeContainer)
        decodedContainer = try decoder.decode(TypeContainer.self, from: encodedContainer)
        XCTAssert(decodedContainer.typed() is String)
    }
}

func unwrap(_ value: TypeContainer) throws -> any Codable {
    try XCTUnwrap(value.typed())
}

fileprivate extension TypeContainer {
    var debugDescription: String {
        self.typed()
            .debugDescription
            .replacingOccurrences(of: "Optional(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "\"", with: "")
    }
}
