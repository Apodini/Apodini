//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini


struct GRPCServiceNameContextKey: OptionalContextKey {
    typealias Value = String
}

public struct GRPCServiceModifier<H: Handler>: HandlerModifier {
    public let component: H
    let serviceName: String

    init(_ component: H, serviceName: String) {
        self.component = component
        self.serviceName = serviceName
    }

    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCServiceNameContextKey.self, value: serviceName, scope: .current)
    }
}

extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func serviceName(_ serviceName: String) -> GRPCServiceModifier<Self> {
        GRPCServiceModifier(self, serviceName: serviceName)
    }
}
