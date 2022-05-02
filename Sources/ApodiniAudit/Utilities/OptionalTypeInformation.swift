//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//


import Foundation
import ApodiniTypeInformation

extension TypeInformation {
    static func buildOptional(_ value: Any, enumAssociatedValues: EnumWithAssociatedValuesHandling = .reject) -> TypeInformation? {
        do {
            return try .init(type: type(of: value), enumAssociatedValues: enumAssociatedValues)
        } catch {
            return nil
        }
    }
}
