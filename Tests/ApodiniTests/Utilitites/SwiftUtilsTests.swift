//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import XCTest
import ApodiniUtils

final class SwiftUtilsTests: XCTestCase {
    func testSets() {
        var set0: Set<Int> = [1, 2]
        let array: [Int] = [3]
        var set1: Set<Int> = [4, 5]

        XCTAssertEqual((set0 + set1), [1, 2, 4, 5])
        XCTAssertEqual(set0 + array, Set([1, 2, 3]))
        XCTAssertEqual(array + set1, Set([3, 4, 5]))

        set0 += 3
        set1 += 3

        XCTAssertEqual(set0, [1, 2, 3])
        XCTAssertEqual(set1, [3, 4, 5])
    }

    func testReduceIntoFirst() {
        let test = [1, 2, 3, 4]
        let empty: [Int] = []

        let result1 = empty.reduceIntoFirst { result, element in
            result + element
        }

        let result2 = test.reduceIntoFirst { result, element in
            result + element
        }

        XCTAssertEqual(result1, nil)
        XCTAssertEqual(result2, 1+2+3+4)
    }

    func testReduceIntoFirstInOut() {
        struct Wrapper: Equatable {
            var num: Int
            init(_ num: Int) {
                self.num = num
            }
        }

        let test: [Wrapper] = [.init(1), .init(2), .init(3), .init(4)]
        let empty: [Wrapper] = []

        let result1 = empty.reduceIntoFirst { result, element in
            result.num += element.num
        }

        let result2 = test.reduceIntoFirst { result, element in
            result.num += element.num
        }

        XCTAssertEqual(result1, nil)
        XCTAssertEqual(result2?.num, 1+2+3+4)
    }

    func testFormatDate() {
        let date = Date(timeIntervalSince1970: 1623843720)

        XCTAssertEqual(date.formatAsIso8601(), "2021-06-16")
        XCTAssertEqual(date.formatAsIso8601(includeTime: true), "2021-06-16T114200")

        XCTAssertEqual(date.format("yyyy-MM-dd_HHmmss"), "2021-06-16_134200")
    }
}
