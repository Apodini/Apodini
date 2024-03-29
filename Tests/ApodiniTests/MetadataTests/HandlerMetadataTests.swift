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
    var metadata: Metadata {
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

            for num in 11...11 {
                TestInt(num)
            }
        }

        for num in 12...13 {
            TestInt(num)
        }

        ReusableTestHandlerMetadata()

        Strings {
            TestString()
        }
    }
}

final class HandlerMetadataTest: ApodiniTests {
    static var expectedIntsState: [Int] {
        [0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15]
    }

    static var expectedInts: [Int] {
        [0, 2, 4, 5, 6, 10, 11, 12, 13, 14, 15]
    }

    func testHandlerMetadataTrue() {
        let visitor = SyntaxTreeVisitor()
        let handler = TestMetadataHandler(state: true)
        handler.accept(visitor)

        let context = visitor.currentNode.export()

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState
        XCTAssertEqual(capturedInts, expectedInts)

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestMetadataHandler")
    }

    func testHandlerMetadataFalse() {
        let visitor = SyntaxTreeVisitor()
        let handler = TestMetadataHandler(state: false)
        handler.accept(visitor)

        let context = visitor.currentNode.export()

        let captured = context.get(valueFor: TestIntMetadataContextKey.self)
        let expected: [Int] = Self.expectedInts
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

        let context = visitor.currentNode.export()

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState + [16, 17]
        XCTAssertEqual(capturedInts, expectedInts)
    }
    
    
    func testDelegatedHandlerMetadata() {
        struct TestDelegatingHandler<D: Handler>: Handler {
            let delegate: Delegate<D>
            
            func handle() throws -> some ResponseTransformable {
                ""
            }
            
            var metadata: Metadata {
                TestInt(42)
                TestString(value: "TestDelegatingHandler")
            }
        }
        
        struct TestDelegatingHandlerInitializer: DelegatingHandlerInitializer {
            func instance<D>(for delegate: D) throws -> SomeHandler<String> where D: Handler {
                SomeHandler(TestDelegatingHandler(delegate: Delegate(delegate)))
            }
        }
        
        
        let visitor = SyntaxTreeVisitor()
        let component = TestMetadataHandler(state: true).delegated(by: TestDelegatingHandlerInitializer())
        
        component.accept(visitor)

        let context = visitor.currentNode.export()

        let capturedInts = context.get(valueFor: TestIntMetadataContextKey.self)
        let expectedInts: [Int] = Self.expectedIntsState
        XCTAssertEqual(capturedInts, expectedInts + [42])

        let capturedStrings = context.get(valueFor: TestStringMetadataContextKey.self)
        XCTAssertEqual(capturedStrings, "TestDelegatingHandler")
    }

    func testDynamicHandlerInitializerMetadataAndDelegateMetadataParsing() throws {
        struct DynamicNameGuard<H: Handler>: Handler {
            let delegate: Delegate<H>

            func handle() async throws -> H.Response {
                try await delegate
                    .environmentObject("Alfred")
                    .instance()
                    .handle()
            }
        }

        struct DynamicNameGuardInitializer: DelegatingHandlerInitializer {
            typealias Response = Never
            func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Response> {
                SomeHandler<Response>(DynamicNameGuard(delegate: Delegate(delegate)))
            }
        }

        struct DynamicIntGuard<H: Handler>: Handler {
            let delegate: Delegate<H>

            func handle() async throws -> H.Response {
                try await delegate
                    .environmentObject(34)
                    .instance()
                    .handle()
            }
        }

        struct DynamicIntGuardInitializer: DelegatingHandlerInitializer {
            typealias Response = Never
            func instance<D: Handler>(for delegate: D) throws -> SomeHandler<Response> {
                SomeHandler<Response>(DynamicIntGuard(delegate: Delegate(delegate)))
            }
        }


        struct DynamicNameGuardMetadata: HandlerMetadataDefinition, DefinitionWithDelegatingHandler {
            typealias Key = DelegatingHandlerContextKey
            let initializer: Key.Value = [.init(DynamicNameGuardInitializer())]
        }

        struct SomeContextKey: OptionalContextKey {
            typealias Value = String
        }

        struct DynamicIntGuardMetadata: HandlerMetadataDefinition, DefinitionWithDelegatingHandler {
            typealias Key = SomeContextKey
            var value = "asdf"
            var initializer: DelegatingHandlerContextKey.Value = [.init(DynamicIntGuardInitializer())]
        }

        struct TestHandler: Handler {
            // simulates extension to the TypedHandlerMetadataNamespace
            typealias NameGuard = DynamicNameGuardMetadata
            typealias IntGuard = DynamicIntGuardMetadata

            @EnvironmentObject
            var passedName: String
            @EnvironmentObject
            var passedAge: Int

            var delegate1 = Delegate(SomeDelegatedHandler1())
            var delegate2 = Delegate(SomeDelegatedHandler3())

            func handle() -> String {
                "Hello \(passedName) \(passedAge)"
            }

            var metadata: Metadata {
                NameGuard()
                IntGuard()

                TestInt(4)
            }
        }

        struct SomeDelegatedHandler1: Handler {
            func handle() -> String {
                fatalError("Not implemented!")
            }

            var metadata: Metadata {
                TestInt(1)
            }
        }

        struct SomeDelegatedHandler2: Handler {
            func handle() -> String {
                fatalError("Not implemented!")
            }

            var metadata: Metadata {
                TestInt(2)
            }
        }

        struct SomeDelegatedHandler3: Handler {
            var delegate = Delegate(SomeDelegatedHandler2())

            func handle() -> String {
                fatalError("Not implemented!")
            }

            var metadata: Metadata {
                TestInt(3)
            }
        }

        let exporter = MockExporter<String>()
        app.registerExporter(exporter: exporter)

        let modelBuilder = SemanticModelBuilder(app)
        let visitor = SyntaxTreeVisitor(modelBuilder: modelBuilder)

        let handler = TestHandler()
        handler.accept(visitor)

        let context = visitor.currentNode.export()

        modelBuilder.finishedRegistration()

        let test = modelBuilder.collectedEndpoints[0]
        print(test)
        let response = exporter.request(on: 0, request: "Example Request", with: app)

        try XCTCheckResponse(
            try XCTUnwrap(response.typed(String.self)),
            content: "Hello Alfred 34"
        )

        XCTAssertEqual(context.get(valueFor: TestIntMetadataContextKey.self), [1, 2, 3, 4])
    }
}
