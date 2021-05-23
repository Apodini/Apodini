//
// Created by Andreas Bauer on 23.05.21.
//

@testable import Apodini
import XCTest
import XCTApodini

fileprivate struct TestIntMetadataContextKey: ContextKey {
    static var defaultValue: [Int] = []

    static func reduce(value: inout [Int], nextValue: () -> [Int]) {
        value.append(contentsOf: nextValue())
    }
}

fileprivate struct TestStringMetadataContextKey: OptionalContextKey {
    typealias Value = String
}


fileprivate extension ContentMetadataNamespace {
    typealias TestInt = TestIntContentMetadata
    typealias Ints = RestrictedContentMetadataGroup<TestInt>
}

fileprivate extension TypedContentMetadataNamespace {
    typealias TestString = GenericTestStringContentMetadata<Self>
    typealias Strings = RestrictedContentMetadataGroup<TestString>
}


fileprivate struct TestIntContentMetadata: ContentMetadataDefinition {
    typealias Key = TestIntMetadataContextKey

    var num: Int
    var value: [Int] {
        [num]
    }

    init(_ num: Int) {
        self.num = num
    }
}

fileprivate struct GenericTestStringContentMetadata<C: Content>: ContentMetadataDefinition {
    typealias Key = TestStringMetadataContextKey

    var value: String = "\(C.self)"
}


struct ReusableTestContentMetadata: ContentMetadataGroup {
    var content: Metadata {
        TestInt(14)
        Empty()
        Collect {
            Empty()
            TestInt(15)
        }
    }
}

fileprivate struct TestMetadataContent: Content {
    static var state = true

    static var metadata: Metadata {
        TestInt(0)

        if state {
            TestInt(1)
        }

        Empty()

        Collect {
            TestInt(2)

            if state {
                TestInt(3)
            } else {
                TestInt(4)
            }

            Empty()

            Collect {
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

            for i in 11...11 {
                TestInt(i)
            }
        }

        for i in 12...13 {
            TestInt(i)
        }

        ReusableTestContentMetadata()

        Strings {
            TestString()
        }
    }
}

fileprivate struct TestMetadataHandler: Handler {
    func handle() -> TestMetadataContent {
        TestMetadataContent()
    }

    var metadata: Metadata {
        Description("Handler Description!")
    }
}

final class ContentMetadataTest: ApodiniTests {
    func testContentMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        TestMetadataContent.state = true
        TestMetadataContent.metadata.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15].reversed()
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
        let expected: [Int] = [0, 2, 4, 5, 6, 10, 11, 12, 13, 14, 15].reversed()
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
        let expectedInts: [Int] = [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15].reversed()
        XCTAssertEqual(capturedInts, expectedInts)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataContent")

        let capturedDescription = context.get(valueFor: DescriptionContextKey.self)
        XCTAssertEqual(capturedDescription, "Handler Description!")
    }
}
