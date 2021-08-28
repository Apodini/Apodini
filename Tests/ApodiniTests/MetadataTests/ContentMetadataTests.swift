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


private extension ContentMetadataNamespace {
    typealias TestInt = TestIntContentMetadata
    typealias Ints = RestrictedContentMetadataBlock<TestInt>
}

private extension TypedContentMetadataNamespace {
    typealias TestString = GenericTestStringContentMetadata<Self>
    typealias Strings = RestrictedContentMetadataBlock<TestString>
}


private struct TestIntContentMetadata: ContentMetadataDefinition {
    typealias Key = TestIntMetadataContextKey

    var num: Int
    var value: [Int] {
        [num]
    }

    init(_ num: Int) {
        self.num = num
    }
}

private struct GenericTestStringContentMetadata<C: Content>: ContentMetadataDefinition {
    typealias Key = TestStringMetadataContextKey

    var value = String(describing: C.self)
}


private struct ReusableTestContentMetadata: ContentMetadataBlock {
    var metadata: Metadata {
        TestInt(14)
        Empty()
        Block {
            Empty()
            TestInt(15)
        }
    }
}

private struct TestMetadataContent: Content {
    static var state = true

    static var metadata: Metadata {
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
                TestInt(5)
                Empty()
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

        ReusableTestContentMetadata()

        Strings {
            TestString()
        }
    }
}

private struct TestMetadataHandler: Handler {
    func handle() -> TestMetadataContent {
        TestMetadataContent()
    }

    var metadata: Metadata {
        Description("Handler Description!")
    }
}

final class ContentMetadataTest: ApodiniTests {
    static var expectedIntsState: [Int] {
        [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15]
    }

    static var expectedInts: [Int] {
        [0, 2, 4, 5, 6, 10, 11, 12, 13, 14, 15]
    }

    func testContentMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        TestMetadataContent.state = true
        TestMetadataContent.metadata.collectMetadata(visitor)

        let context = visitor.currentNode.export()

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState
        XCTAssertEqual(capturedInts, expectedInts)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataContent")
    }

    func testContentMetadataFalse() {
        let visitor = SyntaxTreeVisitor()
        TestMetadataContent.state = false
        TestMetadataContent.metadata.collectMetadata(visitor)

        let context = visitor.currentNode.export()

        let captured = context.get(valueFor: TestIntMetadataContextKey.self)
        let expected: [Int] = Self.expectedInts
        XCTAssertEqual(captured, expected)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataContent")
    }

    func testHandlerWithContent() {
        let visitor = SyntaxTreeVisitor()
        TestMetadataContent.state = true
        let handler = TestMetadataHandler()
        handler.accept(visitor)

        let context = visitor.currentNode.export()
        let contentContext = context.get(valueFor: RootContextOfReturnTypeContextKey.self)

        let capturedInts = contentContext.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState
        XCTAssertEqual(capturedInts, expectedInts)

        let capturedStrings = contentContext.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataContent")

        let capturedDescription = context.get(valueFor: HandlerDescriptionMetadata.self)
        XCTAssertEqual(capturedDescription, "Handler Description!")
    }
}
