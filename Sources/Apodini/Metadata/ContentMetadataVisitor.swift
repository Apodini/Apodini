//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

@_implementationOnly import AssociatedTypeRequirementsVisitor

protocol ContentMetadataVisitor: AssociatedTypeRequirementsTypeVisitor {
    associatedtype Visitor = ContentMetadataVisitor
    associatedtype Input = Content
    associatedtype Output

    func callAsFunction<T: Content>(_ type: T.Type) -> Output
}

private struct TestContent: Content {}

extension ContentMetadataVisitor {
    @inline(never)
    @_optimize(none)
    func _test() { // swiftlint:disable:this identifier_name
        _ = self(TestContent.self) as Output
    }
}
 
struct StandardContentMetadataVisitor: ContentMetadataVisitor {
    let visitor: SyntaxTreeVisitor

    func callAsFunction<T: Content>(_ type: T.Type) {
        type.metadata.collectMetadata(visitor)
    }
}
