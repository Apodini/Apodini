//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini


// MARK: ServiceName

struct GRPCServiceNameContextKey: OptionalContextKey {
    typealias Value = String
}


/// Modifier attaching a gRPC service name to the current sub-tree of the DSL
public struct GRPCServiceModifier<C: Component>: Modifier {
    public let component: C
    let serviceName: String
    
    init(_ component: C, serviceName: String) {
        self.component = component
        self.serviceName = serviceName
    }
    
    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCServiceNameContextKey.self, value: serviceName, scope: .environment)
    }
}

extension GRPCServiceModifier: HandlerModifier, Handler, AnyHandlerMetadata,
                               AnyHandlerMetadataBlock, HandlerMetadataNamespace where Self.ModifiedComponent: Handler {
    public typealias Response = C.Response
}


extension Component {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func gRPCServiceName(_ serviceName: String) -> GRPCServiceModifier<Self> {
        .init(self, serviceName: serviceName)
    }
}
