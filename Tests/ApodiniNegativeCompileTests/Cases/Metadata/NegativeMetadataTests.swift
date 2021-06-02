//
//  File.swift
//  
//
//  Created by Andreas Bauer on 30.05.21.
//

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

    var value: String = "\(C.self)"
}

struct TestStruct: Handler {
    func handle() -> String {
        "Hello World!"
    }
    
    var metadata: Metadata {
        Description("")

        // error: argument type 'AnyContentMetadata' does not conform to expected type 'AnyHandlerMetadata3'
        TestIntContentMetadata(0)
    }
}
