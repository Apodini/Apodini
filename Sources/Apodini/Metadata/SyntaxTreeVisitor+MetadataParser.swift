//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import MetadataSystem

extension SyntaxTreeVisitor: MetadataParser {
    // override the default visit to handle `AnyDefinitionWithDynamicDelegatingHandler`.
    public func visit<Definition: MetadataDefinition>(definition: Definition) {
        self.addContext(Definition.Key.self, value: definition.value, scope: Definition.scope)

        if let metadataWithDelegatingHandler = definition as? any AnyDefinitionWithDynamicDelegatingHandler {
            metadataWithDelegatingHandler.addInitializerContextValue(self)
        }
    }
}
