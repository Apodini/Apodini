//
// Created by Andreas Bauer on 22.05.21.
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


fileprivate extension HandlerMetadataNamespace {
    typealias TestInt = TestIntHandlerMetadata
    typealias Ints = RestrictedHandlerMetadataGroup<TestInt>
}

fileprivate extension TypedHandlerMetadataNamespace {
    typealias TestString = GenericTestStringHandlerMetadata<Self>
    typealias Strings = RestrictedHandlerMetadataGroup<TestString>
}


fileprivate struct TestIntHandlerMetadata: HandlerMetadataDefinition {
    typealias Key = TestIntMetadataContextKey

    var num: Int
    var value: [Int] {
        [num]
    }

    init(_ num: Int) {
        self.num = num
    }
}

fileprivate struct GenericTestStringHandlerMetadata<H: Handler>: HandlerMetadataDefinition {
    typealias Key = TestStringMetadataContextKey

    var value: String = "\(H.self)"
}

fileprivate struct ReusableTestHandlerMetadata: HandlerMetadataGroup {
    var content: Metadata {
        TestInt(14)
        Empty()
        Collect {
            Empty()
            TestInt(15)
        }
    }
}

fileprivate struct TestMetadataHandler: Handler {
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

        Collect {
            TestInt(2)

            if state {
                TestInt(3)
            } else {
                TestInt(4)
            }

            Empty()

            Collect {
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

            for i in 11...11 {
                TestInt(i)
            }
        }

        for i in 12...13 {
            TestInt(i)
        }

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
    func testHandlerMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        visitor.currentNode = UnresettableContextNode()
        let handler = TestMetadataHandler(state: true)
        handler.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15].reversed()
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
        let expected: [Int] = [0, 2, 4, 5, 6, 10, 11, 12, 13, 14, 15].reversed()
        XCTAssertEqual(captured, expected)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataHandler")
    }

    func testComponentMetadataModifier() {
        let visitor = SyntaxTreeVisitor()
        let component = TestMetadataHandler(state: true)
            .metadata(TestIntHandlerMetadata(16))
            .metadata {
                TestIntHandlerMetadata(17)
            }
        component.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15].reversed() + [16, 17]
        XCTAssertEqual(capturedInts, expectedInts)
    }
}
