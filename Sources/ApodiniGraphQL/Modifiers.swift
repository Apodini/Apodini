//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini


// MARK: TMP_GraphQLRootQueryFieldName

struct TMP_GraphQLRootQueryFieldName: OptionalContextKey {
    typealias Value = String
}


/// Modifier for specifying a handler's GraphQL root query field name. Provisional.
public struct TMP_GraphQLRootQueryFieldNameModifier<H: Handler>: HandlerModifier {
    public let component: H
    let fieldName: String
    
    init(_ component: H, fieldName: String) {
        self.component = component
        self.fieldName = fieldName
    }
    
    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(TMP_GraphQLRootQueryFieldName.self, value: fieldName, scope: .current)
    }
}

//extension GRPCServiceModifier: HandlerModifier, Handler, AnyHandlerMetadata,
//                               AnyHandlerMetadataBlock, HandlerMetadataNamespace where Self.ModifiedComponent: Handler {
//    public typealias Response = C.Response
//}


extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func graphqlRootQueryFieldName(_ fieldName: String) -> TMP_GraphQLRootQueryFieldNameModifier<Self> {
        .init(self, fieldName: fieldName)
    }
}
