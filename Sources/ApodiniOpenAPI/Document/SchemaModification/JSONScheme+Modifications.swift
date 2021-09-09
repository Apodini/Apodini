//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import Apodini
import OpenAPIKit


extension JSONSchema {
    func evaluateModifications(containedIn context: Context?) -> JSONSchema {
        var ignored: JSONSchemeModification?
        let result = evaluateModifications(containedIn: context, writingPendingPropertyProcessingInto: &ignored)
        precondition(ignored == nil, "Can't ignore non empty property post processing information!")
        return result
    }

    func evaluateModifications(
        containedIn context: Context?,
        writingPendingPropertyProcessingInto schemeModification: inout JSONSchemeModification?
    ) -> JSONSchema {
        guard let context = context else {
            return self
        }

        let modifications = context.get(valueFor: OpenAPIJSONSchemeModificationContextKey.self)

        var modification = JSONSchemeModification(with: modifications)
        modification.mapContextKeys(from: context) // source modifications from other context keys (e.g. standard Description)

        let resultingScheme = modification(on: self)

        if modification.hasPendingPropertyModifications {
            schemeModification = modification
        }

        return resultingScheme
    }
}
