//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Foundation

extension Application {
    var temperatureService: TemperatureService {
        TemperatureService()
    }
}

struct TemperatureService {
    func callAsFunction(_ date: Date, _ location: Coordinates) throws -> Double {
        let sunShift = sin(2.0 * Double.pi * Double(date.dayOfYear - 120) / 365.0)
        
        return 40 * cos(Double.pi * (location.latitude - 30 * sunShift) / 90.0)
    }
}

extension Date {
    var dayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: self)!
    }
}
