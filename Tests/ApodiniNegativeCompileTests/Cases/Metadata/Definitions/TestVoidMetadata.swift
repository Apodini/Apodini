//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
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
