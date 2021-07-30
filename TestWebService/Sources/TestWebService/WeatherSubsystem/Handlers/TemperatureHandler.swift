//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//             

import Apodini
import Foundation

struct GetTemperature: Handler {
    @Binding var date: Date

    @Location var location: Coordinates

    @Environment(\.temperatureService) var temperature

    func handle() throws -> Double {
        try temperature(date, location)
    }
}

@propertyWrapper
struct Location: DynamicProperty {
    @Binding var latitude: Double
    @Binding var longitude: Double

    var wrappedValue: Coordinates {
        (latitude, longitude)
    }
}
