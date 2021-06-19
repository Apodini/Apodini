//
// Created by Andreas Bauer on 06.06.21.
//

import Apodini

struct TestVoidContextKey: ContextKey {
    typealias Value = Void
    static var defaultValue: Void = ()
}


struct TestVoidHandlerMetadata: HandlerMetadataDefinition {
    typealias Key = TestVoidContextKey
    var value: Void = ()
}

struct TestVoidWebServiceMetadata: WebServiceMetadataDefinition {
    typealias Key = TestVoidContextKey
    var value: Void = ()
}

struct TestVoidComponentOnlyMetadata: ComponentOnlyMetadataDefinition {
    typealias Key = TestVoidContextKey
    var value: Void = ()
}

struct TestVoidComponentMetadata: ComponentMetadataDefinition {
    typealias Key = TestVoidContextKey
    var value: Void = ()
}

struct TestVoidContentMetadata: ContentMetadataDefinition {
    typealias Key = TestVoidContextKey
    var value: Void = ()
}
