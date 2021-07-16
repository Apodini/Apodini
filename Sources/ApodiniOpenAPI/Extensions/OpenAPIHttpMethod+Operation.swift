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

extension OpenAPIKit.OpenAPI.HttpMethod {
    init(_ operation: Apodini.Operation) {
        switch operation {
        case .read:
            self = .get
        case .create:
            self = .post
        case .update:
            self = .put
        case .delete:
            self = .delete
        }
    }
}
