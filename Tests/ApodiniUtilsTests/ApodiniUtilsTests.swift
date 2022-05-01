//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import ApodiniUtils


class ApodiniUtilsTests: XCTestCase {
    func testStringWhitespaceTrimming() {
        XCTAssertEqual("Hello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual(" Hello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual(" Hello World".trimmingTrailingWhitespace(), " Hello World")
        XCTAssertEqual("\tHello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual(" \t Hello World".trimmingLeadingWhitespace(), "Hello World")
        XCTAssertEqual("Hello World\t".trimmingTrailingWhitespace(), "Hello World")
        XCTAssertEqual("Hello\tWorld".trimmingLeadingWhitespace(), "Hello\tWorld")
        XCTAssertEqual("Hello\tWorld".trimmingTrailingWhitespace(), "Hello\tWorld")
        XCTAssertEqual("\tHello World\t".trimmingLeadingAndTrailingWhitespace(), "Hello World")
    }
    
    
    func testCreateStringFromInt8Tuple() throws {
        let cString = strdup("abcd")!
        defer { free(cString) }
        
        XCTAssertEqual("abcd", try XCTUnwrap(String.createFromInt8Tuple(
            (cString[0], cString[1], cString[2], cString[3])
        )))
    }
    
    
    func testBitset() {
        var bitset: UInt8 = 0
        bitset[bitAt: 0] = true
        XCTAssertEqual(bitset, 1)
        XCTAssertEqual(bitset.binaryString, "00000001")
        bitset.toggleBit(at: 2)
        XCTAssertEqual(bitset, 5)
        XCTAssertEqual(bitset.binaryString, "00000101")
        bitset.replaceBits(in: 4..<7, withEquivalentRangeIn: 112) // 112 = 0b01110101
        XCTAssertEqual(bitset, 117)
        XCTAssertEqual(bitset.binaryString, "01110101")
    }
    
    
    func testSequenceToDictionary() {
        XCTAssertEqual([1, 2, 3, 4].mapIntoDict { ($0, $0) }, [
            1: 1,
            2: 2,
            3: 3,
            4: 4
        ])
        XCTAssertEqual([1, 2, 3, 4].mapIntoDict { (String($0), $0) }, [
            "1": 1,
            "2": 2,
            "3": 3,
            "4": 4
        ])
        XCTAssertEqual([1, 2, 3, 4].mapIntoDict { ($0 % 2, $0) }, [
            1: 3,
            0: 4
        ])
    }
    
    
    func testThreeWayComparable() {
        XCTAssertEqual(0.compareThreeWay(0), .orderedSame)
        XCTAssertEqual(0.compareThreeWay(1), .orderedAscending)
        XCTAssertEqual(1.compareThreeWay(0), .orderedDescending)
    }
    
    
    
    func testOtherUtilities() throws {
        errno = EPERM
        do {
            try throwIfPosixError(errno)
        } catch {
            //let error = try XCTUnwrap(error as NSError)
            XCTAssertEqual(error as NSError, NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: [
                NSLocalizedDescriptionKey: "Operation not permitted"
            ]))
        }
    }
}
