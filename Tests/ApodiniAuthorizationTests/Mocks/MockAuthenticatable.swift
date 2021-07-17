//
// Created by Andreas Bauer on 17.07.21.
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
