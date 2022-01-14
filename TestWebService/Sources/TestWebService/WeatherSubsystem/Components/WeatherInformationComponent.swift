//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Foundation

struct WeatherInformationComponent: Component {
    let date: Binding<Date>
    let location: Location
    let endpointNameContext: String
    
    var content: some Component {
        Group("temperature") {
            GetTemperature(date: date, location: location)
                .endpointName("get\(endpointNameContext.capitalisingFirstCharacter)Temperature")
        }
        Group("danger") {
            GetDanger(date: date, location: location)
                .endpointName("get\(endpointNameContext.capitalisingFirstCharacter)Danger")
        }
    }
}
