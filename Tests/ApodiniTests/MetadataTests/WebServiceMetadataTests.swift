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

        ReusableTestWebServiceMetadata()

        Strings {
            TestString()
        }
    }
}

final class WebServiceMetadataTest: ApodiniTests {
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

    func testWebServiceMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        let webService = TestMetadataWebService(state: true)
        webService.visit(visitor)

        let context = Context(contextNode: visitor.currentNode)

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

        let context = Context(contextNode: visitor.currentNode)

        let captured = context.get(valueFor: TestIntMetadataContextKey.self)
        let expected: [Int] = Self.expectedInts
        XCTAssertEqual(captured, expected)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataWebService")
    }
}
