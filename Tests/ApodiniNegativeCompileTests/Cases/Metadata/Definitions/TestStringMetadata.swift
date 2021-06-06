//
// Created by Andreas Bauer on 06.06.21.
//

import Apodini

private struct TestStringMetadataContextKey: OptionalContextKey {
    typealias Value = String
}

// TODO remove?

/*
private extension TypedContentMetadataNamespace {
    typealias TestString = GenericTestStringContentMetadata<Self>
    typealias Strings = RestrictedContentMetadataBlock<TestString>
}
private struct GenericTestStringContentMetadata<C: Content>: ContentMetadataDefinition {
    typealias Key = TestStringMetadataContextKey

    var value: String = "\(C.self)"
}
*/
