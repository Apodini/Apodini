//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Foundation

struct GetDanger: Handler {
    @Binding var date: Date

    @Location var location: Coordinates

    @Environment(\.temperatureService) var temperature

    func handle() throws -> Bool {
        let temperature = try temperature(date, location)
        return temperature < -20.0 || temperature > 40.0
    }
}
