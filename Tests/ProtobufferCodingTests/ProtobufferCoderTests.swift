//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Foundation
import XCTest
@testable import ProtobufferCoding

class ProtobufferCoderTests: XCTestCase {
    func testRoundripInteger() throws {
        struct Box: Codable, Equatable {
            let value: Int
        }
        
        let value = Box(value: 32)
        
        let encoder = ProtobufferEncoder()
        encoder.integerWidthCodingStrategy = .thirtyTwo
        
        let encoded = try encoder.encode(value)
        
        let decoder = ProtobufferDecoder()
        decoder.integerWidthCodingStrategy = .thirtyTwo
        
        let decoded = try decoder.decode(Box.self, from: encoded)
        
        XCTAssertEqual(decoded, value)
    }
    
    func testRoundripIntegerUnsignedRepeated() throws {
        struct Box: Codable, Equatable {
            let values: [UInt]
        }
        
        let value = Box(values: [32])
        
        let encoder = ProtobufferEncoder()
        encoder.integerWidthCodingStrategy = .thirtyTwo
        
        let encoded = try encoder.encode(value)
        
        let decoder = ProtobufferDecoder()
        decoder.integerWidthCodingStrategy = .thirtyTwo
        
        let decoded = try decoder.decode(Box.self, from: encoded)
        
        XCTAssertEqual(decoded, value)
    }
}
