//
// This source file is part of the Apodini open source project
// 
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//
import Apodini

struct GRPCMethodNameContextKey: OptionalContextKey {
    typealias Value = String
}

public struct GRPCMethodModifier<H: Handler>: HandlerModifier {
    public let component: H
    let methodName: String

    init(_ component: H, methodName: String) {
        self.component = component
        self.methodName = methodName
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCMethodNameContextKey.self, value: methodName, scope: .current)
    }
}

extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func rpcName(_ methodName: String) -> GRPCMethodModifier<Self> {
        GRPCMethodModifier(self, methodName: methodName)
    }
}
