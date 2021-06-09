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


private extension ComponentMetadataNamespace {
    typealias TestInt = TestIntComponentMetadata
    typealias Ints = RestrictedComponentMetadataBlock<TestInt>
}

private extension TypedComponentMetadataNamespace {
    typealias TestString = GenericTestStringComponentMetadata<Self>
    typealias Strings = RestrictedComponentMetadataBlock<TestString>
}


private struct TestIntComponentMetadata: ComponentMetadataDefinition {
    typealias Key = TestIntMetadataContextKey

    var num: Int
    var value: [Int] {
        [num]
    }

    init(_ num: Int) {
        self.num = num
    }
}

private struct GenericTestStringComponentMetadata<C: Component>: ComponentMetadataDefinition {
    typealias Key = TestStringMetadataContextKey

    var value = String(describing: C.self)
}

private struct ReusableTestComponentMetadata: ComponentMetadataBlock {
    let offset: Int
    let state: Bool

    var content: Metadata {
        TestInt(offset)
        Empty()
        Block {
            TestInt(offset + 1)
            Empty()
        }

        if state {
            TestInt(offset + 2)
        }

        if state {
            TestInt(offset + 3)
        } else {
            TestInt(offset + 4)
        }

        #if swift(>=5.4)
        for num in (offset + 5) ... (offset + 7) {
            TestInt(num)
        }
        #endif
    }
}

private struct TestMetadataHandler: Handler {
    func handle() -> String {
        "Hello World!"
    }

    var metadata: Metadata {
        Ints {
            TestInt(99)
        }
        TestInt(100)
    }
}

private struct TestMetadataComponent: Component {
    var state: Bool

    var content: some Component {
        TestMetadataHandler()
            .metadata(TestInt(97))
            .metadata {
                TestInt(98)
            }
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

        ReusableTestComponentMetadata(offset: 14, state: true)
        ReusableTestComponentMetadata(offset: 22, state: false)

        Strings {
            TestString()
        }
    }
}

private struct TestMetadataWebService: WebService {
    typealias Content = Never
    var content: Never {
        fatalError("Never can't produce content!")
    }

    var metadata: Metadata {
        Ints {
            TestInt(99)
        }
        TestInt(100)
    }
}

final class ComponentMetadataTest: ApodiniTests {
    static var expectedIntsState: [Int] {
        #if swift(>=5.4)
        [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21, 22, 23, 26, 27, 28, 29].reversed()
        #else
        // swiftlint:disable:next comma
        return [0, 1, 2, 3, 5, 6, 7, 8, 9,             14, 15, 16, 17,             22, 23, 26            ].reversed()
        #endif
    }

    static var expectedInts: [Int] {
        #if swift(>=5.4)
        [0, 2, 4, 5, 6, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21, 22, 23, 26, 27, 28, 29].reversed()
        #else
        // swiftlint:disable:next comma
        return [0, 2, 4, 5, 6, 10,             14, 15, 16, 17,             22, 23, 26            ].reversed()
        #endif
    }

    func testComponentMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        let component = TestMetadataComponent(state: true)
        component.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState
        XCTAssertEqual(capturedInts, expectedInts)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataComponent")
    }

    func testComponentMetadataFalse() {
        let visitor = SyntaxTreeVisitor()
        visitor.currentNode = UnresettableContextNode()
        let component = TestMetadataComponent(state: false)
        component.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let captured = context.get(valueFor: TestIntMetadataContextKey.self)
        let expected: [Int] = Self.expectedInts
        XCTAssertEqual(captured, expected)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataComponent")
    }

    func testComponentMetadataModifier() {
        let visitor = SyntaxTreeVisitor()
        let component = TestMetadataComponent(state: true)
            .metadata(TestIntComponentMetadata(30))
            .metadata {
                TestIntComponentMetadata(31)
            }
        component.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState
            + [30, 31]
        XCTAssertEqual(capturedInts, expectedInts)
    }

    func testComponentMetadataOnHandler() {
        let visitor = SyntaxTreeVisitor()
        visitor.currentNode = UnresettableContextNode()
        let handler = TestMetadataHandler()
        handler.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        XCTAssertEqual(capturedInts, [100, 99])
    }

    func testComponentMetadataOnWebService() {
        let visitor = SyntaxTreeVisitor()
        let webService = TestMetadataWebService()
        webService.visit(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        XCTAssertEqual(capturedInts, [100, 99])
    }

    func testComponentMetadataInheritance() throws {
        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)
        let component = TestMetadataComponent(state: true)
        component.accept(visitor)
        visitor.finishParsing()

        let endpoint: AnyEndpoint = try XCTUnwrap(modelBuilder.rootNode.endpoints.first?.value)

        let capturedInts = endpoint[Context.self].get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = [100, 99, 97] + Self.expectedIntsState + [98]
        XCTAssertEqual(capturedInts, expectedInts)
    }
}
