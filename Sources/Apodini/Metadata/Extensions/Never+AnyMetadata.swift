//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

extension Never: AnyMetadata {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        // as the Never also conforms to Component, we need to manually specify the implementation
        fatalError("Never cannot be accepted by the SyntaxTreeVisitor!")
    }
}
