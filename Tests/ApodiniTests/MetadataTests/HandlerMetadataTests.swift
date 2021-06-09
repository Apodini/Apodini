//
// Created by Andreas Bauer on 22.05.21.
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


private extension HandlerMetadataNamespace {
    typealias TestInt = TestIntHandlerMetadata
    typealias Ints = RestrictedHandlerMetadataBlock<TestInt>
}

private extension TypedHandlerMetadataNamespace {
    typealias TestString = GenericTestStringHandlerMetadata<Self>
    typealias Strings = RestrictedHandlerMetadataBlock<TestString>
}


private struct TestIntHandlerMetadata: HandlerMetadataDefinition {
    typealias Key = TestIntMetadataContextKey

    var num: Int
    var value: [Int] {
        [num]
    }

    init(_ num: Int) {
        self.num = num
    }
}

private struct GenericTestStringHandlerMetadata<H: Handler>: HandlerMetadataDefinition {
    typealias Key = TestStringMetadataContextKey

    var value = String(describing: H.self)
}

private struct ReusableTestHandlerMetadata: HandlerMetadataBlock {
    var content: Metadata {
        TestInt(14)
        Empty()
        Block {
            Empty()
            TestInt(15)
        }
    }
}

private struct TestMetadataHandler: Handler {
    var state: Bool

    func handle() -> String {
        "Hello Test!"
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

        ReusableTestHandlerMetadata()

        Strings {
            TestString()
        }
    }
}

class UnresettableContextNode: ContextNode {
    override func resetContextNode() {}
}

final class HandlerMetadataTest: ApodiniTests {
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

    func testHandlerMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        visitor.currentNode = UnresettableContextNode()
        let handler = TestMetadataHandler(state: true)
        handler.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState
        XCTAssertEqual(capturedInts, expectedInts)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataHandler")
    }

    func testHandlerMetadataFalse() {
        let visitor = SyntaxTreeVisitor()
        visitor.currentNode = UnresettableContextNode()
        let handler = TestMetadataHandler(state: false)
        handler.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let captured = context.get(valueFor: TestIntMetadataContextKey.self)
        let expected: [Int] = Self.expectedInts
        XCTAssertEqual(captured, expected)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataHandler")
    }

    func testComponentMetadataModifier() {
        let visitor = SyntaxTreeVisitor()
        visitor.currentNode = UnresettableContextNode()
        let component = TestMetadataHandler(state: true)
            .metadata(TestIntHandlerMetadata(16))
            .metadata {
                TestIntHandlerMetadata(17)
            }
        component.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState + [16, 17]
        XCTAssertEqual(capturedInts, expectedInts)
    }
}
