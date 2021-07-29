//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@testable import Apodini
import XCTest
import XCTApodini

private struct TestIntMetadataContextKey: ContextKey {
    typealias Value = [Int]
    static var defaultValue: [Int] = []
}

private struct TestStringMetadataContextKey: OptionalContextKey {
    typealias Value = String
}


private extension WebServiceMetadataNamespace {
    typealias TestInt = TestIntWebServiceMetadata
    typealias Ints = RestrictedWebServiceMetadataBlock<TestInt>
}

private extension TypedWebServiceMetadataNamespace {
    typealias TestString = GenericTestStringWebServiceMetadata<Self>
    typealias Strings = RestrictedWebServiceMetadataBlock<TestString>
}


private struct TestIntWebServiceMetadata: WebServiceMetadataDefinition {
    typealias Key = TestIntMetadataContextKey

    var num: Int
    var value: [Int] {
        [num]
    }

    init(_ num: Int) {
        self.num = num
    }
}

private struct GenericTestStringWebServiceMetadata<W: WebService>: WebServiceMetadataDefinition {
    typealias Key = TestStringMetadataContextKey

    var value = String(describing: W.self)
}


private struct ReusableTestWebServiceMetadata: WebServiceMetadataBlock {
    var content: Metadata {
        TestInt(14)
        Empty()
        Block {
            Empty()
            TestInt(15)
        }
    }
}

private struct TestMetadataWebService: WebService {
    typealias Content = Never

    var state: Bool

    init() {
        state = true
    }

    init(state: Bool) {
        self.state = state
    }

    var content: Never {
        fatalError("Never can't produce content!")
    }

    var metadata: Metadata {
        TestInt(0)

        if state {
            TestInt(1)
        }

        Empty()

        Block {
            TestInt(2)

            if state {
                TestInt(3)
            } else {
                TestInt(4)
            }

            Empty()

            Block {
                Empty()
                TestInt(5)
            }

            TestInt(6)
        }

        Ints {
            if state {
                Ints {
                    TestInt(7)
                }
                TestInt(8)
            }

            if state {
                TestInt(9)
            } else {
                TestInt(10)
            }

            for num in 11...11 {
                TestInt(num)
            }
        }

        for num in 12...13 {
            TestInt(num)
        }

        ReusableTestWebServiceMetadata()

        Strings {
            TestString()
        }
    }
}

final class WebServiceMetadataTest: ApodiniTests {
    static var expectedIntsState: [Int] {
        [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15]
    }

    static var expectedInts: [Int] {
        [0, 2, 4, 5, 6, 10, 11, 12, 13, 14, 15]
    }

    func testWebServiceMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        let webService = TestMetadataWebService(state: true)
        webService.visit(visitor)

        let context = visitor.currentNode.export()

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState
        XCTAssertEqual(capturedInts, expectedInts)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataWebService")
    }

    func testWebServiceMetadataFalse() {
        let visitor = SyntaxTreeVisitor()
        let webService = TestMetadataWebService(state: false)
        webService.visit(visitor)

        let context = visitor.currentNode.export()

        let captured = context.get(valueFor: TestIntMetadataContextKey.self)
        let expected: [Int] = Self.expectedInts
        XCTAssertEqual(captured, expected)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataWebService")
    }
}
