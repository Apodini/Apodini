//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import ApodiniAuthorization

struct MockCredentials<State>: Authenticatable {
    var username: String
    var password: String

    var email: String
    var state: State

    var someState = true
}

struct MockToken: Authenticatable, Codable {
    let id: String
    let email: String
    let state: Bool
    let optionalState: String?

    func toJson() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "ERR"
    }
}
