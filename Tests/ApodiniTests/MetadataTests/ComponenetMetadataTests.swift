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


fileprivate extension ComponentMetadataNamespace {
    typealias TestInt = TestIntComponentMetadata
    typealias Ints = RestrictedComponentMetadataGroup<TestInt>
}

fileprivate extension TypedComponentMetadataNamespace {
    typealias TestString = GenericTestStringComponentMetadata<Self>
    typealias Strings = RestrictedComponentMetadataGroup<TestString>
}


fileprivate struct TestIntComponentMetadata: ComponentMetadataDefinition {
    typealias Key = TestIntMetadataContextKey

    var num: Int
    var value: [Int] {
        [num]
    }

    init(_ num: Int) {
        self.num = num
    }
}

fileprivate struct GenericTestStringComponentMetadata<C: Component>: ComponentMetadataDefinition {
    typealias Key = TestStringMetadataContextKey

    var value: String = "\(C.self)"
}

fileprivate struct ReusableTestComponentMetadata: ComponentMetadataGroup {
    let offset: Int
    let state: Bool

    var content: Metadata {
        TestInt(offset)
        Empty()
        Collect {
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

        for i in (offset + 5) ... (offset + 7) {
            TestInt(i)
        }
    }
}

fileprivate struct TestMetadataHandler: Handler {
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

fileprivate struct TestMetadataComponent: Component {
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

        ReusableTestComponentMetadata(offset: 14, state: true)
        ReusableTestComponentMetadata(offset: 14+8, state: false)

        Strings {
            TestString()
        }
    }
}

fileprivate struct TestMetadataWebService: WebService {
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
    func testComponentMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        let component = TestMetadataComponent(state: true)
        component.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21, 22, 23, 26, 27, 28, 29].reversed()
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
        let expected: [Int] = [0, 2, 4, 5, 6, 10, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21, 22, 23, 26, 27, 28, 29].reversed()
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
        let expectedInts: [Int] = [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21, 22, 23, 26, 27, 28, 29].reversed()
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
        let expectedInts: [Int] = [100, 99, 97, 29, 28, 27, 26, 23, 22, 21, 20, 19, 17, 16, 15, 14, 13, 12, 11, 9, 8, 7, 6, 5, 3, 2, 1, 0, 98]
        XCTAssertEqual(capturedInts, expectedInts)
    }
}
