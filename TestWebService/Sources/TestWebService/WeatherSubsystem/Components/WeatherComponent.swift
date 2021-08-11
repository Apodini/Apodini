//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Foundation

struct WeatherComponent: Component, EnvironmentAccessible {
    @Parameter var date = Date()
    @Parameter var latitude: Double
    @Parameter var longitude: Double
    
    @Environment(\Self.date) var injectedDate: Date
    @Environment(\Self.latitude) var injectedLatitude: Double
    @Environment(\Self.longitude) var injectedLongitude: Double
    
    var content: some Component {
        Group("weather") {
            WeatherInformationComponent(date: $date,
                                        location: Location(latitude: $latitude,
                                                           longitude: $longitude))
            Group("trip") {
                // Munich to Cape Town: ?startLatitude=48.13799&startLongitude=11.57518&endLatitude=-33.92522&endLongitude=18.42408
                // Munich to Frankfurt: ?startLatitude=48.13799&startLongitude=11.57518&endLatitude=50.11044&endLongitude=8.68183
                WeatherInformationComponent(date: $injectedDate,
                                            location: Location(latitude: $injectedLatitude,
                                                               longitude: $injectedLongitude))
                    .asRoute()
            }
        }
    }
}
