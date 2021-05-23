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
    typealias TestInt = TestIntComponentOnlyMetadata
    typealias Ints = RestrictedComponentOnlyMetadataGroup<TestInt>
}

fileprivate extension TypedComponentMetadataNamespace {
    typealias TestString = GenericTestStringComponentOnlyMetadata<Self>
    typealias Strings = RestrictedComponentOnlyMetadataGroup<TestString>
}


fileprivate struct TestIntComponentOnlyMetadata: ComponentOnlyMetadataDefinition {
    typealias Key = TestIntMetadataContextKey

    var num: Int
    var value: [Int] {
        [num]
    }

    init(_ num: Int) {
        self.num = num
    }
}

fileprivate struct GenericTestStringComponentOnlyMetadata<C: Component>: ComponentOnlyMetadataDefinition {
    typealias Key = TestStringMetadataContextKey

    var value: String = "\(C.self)"
}


struct ReusableTestComponentOnlyMetadata: ComponentOnlyMetadataGroup {
    var content: Metadata {
        TestInt(14)
        Empty()
        Collect {
            Empty()
            TestInt(15)
        }
    }
}

fileprivate struct TestMetadataComponent: Component {
    typealias Content = Never

    var state: Bool

    var content: Never {
        fatalError("Never can't produce content!")
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

        ReusableTestComponentOnlyMetadata()

        Strings {
            TestString()
        }
    }
}

fileprivate struct GroupComponentWithMetadata<Content: Component>: Component, SyntaxTreeVisitable {
    let content: Content

    init(@ComponentBuilder content: () -> Content) {
        self.content = content()
    }

    var metadata: Metadata {
        TestInt(3)
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.enterContent {
            visitor.enterComponentContext {
                if Content.self != Never.self {
                    content.accept(visitor)
                }
            }
        }
    }
}

final class ComponentOnlyMetadataTest: ApodiniTests {
    func testComponentOnlyMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        let component = TestMetadataComponent(state: true)
        component.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15].reversed()
        XCTAssertEqual(capturedInts, expectedInts)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataComponent")
    }

    func testComponentOnlyMetadataFalse() {
        let visitor = SyntaxTreeVisitor()
        let component = TestMetadataComponent(state: false)
        component.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let captured = context.get(valueFor: TestIntMetadataContextKey.self)
        let expected: [Int] = [0, 2, 4, 5, 6, 10, 11, 12, 13, 14, 15].reversed()
        XCTAssertEqual(captured, expected)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataComponent")
    }

    func testComponentMetadataModifier() {
        let visitor = SyntaxTreeVisitor()
        let component = TestMetadataComponent(state: true)
            .metadata(TestIntComponentOnlyMetadata(16))
            .metadata {
                TestIntComponentOnlyMetadata(17)
            }
        component.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15].reversed() + [16, 17]
        XCTAssertEqual(capturedInts, expectedInts)
    }

    func testGroupComponentWithMetadata() {
        let visitor = SyntaxTreeVisitor()
        let component: some Component = GroupComponentWithMetadata {
            EmptyComponent()
        }
        component.accept(visitor)

        let context = Context(contextNode: visitor.currentNode)

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = [3]
        XCTAssertEqual(capturedInts, expectedInts)
    }
}
