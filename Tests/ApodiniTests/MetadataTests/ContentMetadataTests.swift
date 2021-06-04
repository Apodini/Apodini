//
// Created by Andreas Bauer on 23.05.21.
//

@testable import Apodini
import XCTest
import XCTApodini

private struct TestIntMetadataContextKey: ContextKey {
    static var defaultValue: [Int] = []

    static func reduce(value: inout [Int], nextValue: () -> [Int]) {
        value.append(contentsOf: nextValue())
    }
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
    var content: Metadata {
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

            #if swift(>=5.4)
            for num in 11...11 {
                TestInt(num)
            }
            #endif
        }

        #if swift(>=5.4)
        for num in 12...13 {
            TestInt(num)
        }
        #endif

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
        #if swift(>=5.4)
        [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15].reversed()
        #else
        // swiftlint:disable:next comma
        return [0, 1, 2, 3, 5, 6, 7, 8, 9,             14, 15].reversed()
        #endif
    }

    static var expectedInts: [Int] {
        #if swift(>=5.4)
        [0, 2, 4, 5, 6, 10, 11, 12, 13, 14, 15].reversed()
        #else
        // swiftlint:disable:next comma
        return [0, 2, 4, 5, 6, 10,             14, 15].reversed()
        #endif
    }

    func testContentMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        TestMetadataContent.state = true
        TestMetadataContent.metadata.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState
        XCTAssertEqual(capturedInts, expectedInts)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataContent")
    }

    func testContentMetadataFalse() {
        let visitor = SyntaxTreeVisitor()
        TestMetadataContent.state = false
        TestMetadataContent.metadata.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let captured = context.get(valueFor: TestIntMetadataContextKey.self)
        let expected: [Int] = Self.expectedInts
        XCTAssertEqual(captured, expected)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataContent")
    }

    func testHandlerWithContent() {
        let visitor = SyntaxTreeVisitor()
        visitor.currentNode = UnresettableContextNode()
        TestMetadataContent.state = true
        let handler = TestMetadataHandler()
        handler.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState
        XCTAssertEqual(capturedInts, expectedInts)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataContent")

        let capturedDescription = context.get(valueFor: DescriptionContextKey.self)
        XCTAssertEqual(capturedDescription, "Handler Description!")
    }
}
