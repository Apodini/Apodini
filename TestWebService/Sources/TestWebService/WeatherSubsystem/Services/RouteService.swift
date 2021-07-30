//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Foundation

typealias Coordinates = (latitude: Double, longitude: Double)

extension Application {
    var routeService: RouteService {
        RouteService()
    }
}

struct RouteService {
    func callAsFunction(_ date: Date, start: Coordinates, end: Coordinates) throws -> [(Date, Coordinates)] {
        recursivePathFinding(start: (date, start), end: (date.advanced(by: (distance(between: start, and: end) / 50) * 3600.0), end))
    }
    
    private func recursivePathFinding(start: (date: Date, location: Coordinates), end: (date: Date, location: Coordinates)) -> [(Date, Coordinates)] {
        if distance(between: start.location, and: end.location) <= 5.0 {
            return [start, end]
        } else {
            let middle = (date: start.date.advanced(by: end.date.timeIntervalSince(start.date) / 2),
                          location: ((start.location.latitude + end.location.latitude) / 2, (start.location.longitude + end.location.longitude) / 2))
                          
            return recursivePathFinding(start: start, end: middle) + recursivePathFinding(start: middle, end: end)[1...]
        }
    }
}


func distance(between start: Coordinates, and end: Coordinates) -> Double {
    distanceInKmBetweenEarthCoordinates(lat1: start.latitude, lon1: start.longitude, lat2: end.latitude, lon2: end.longitude)
}
    
// https://stackoverflow.com/a/365853/9816338

private func degreesToRadians(_ degrees: Double) -> Double {
    degrees * Double.pi / 180.0;
}

private func distanceInKmBetweenEarthCoordinates(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
    let earthRadiusKm = 6371.0;

    let dLat = degreesToRadians(lat2-lat1);
    let dLon = degreesToRadians(lon2-lon1);

    let lat1 = degreesToRadians(lat1);
    let lat2 = degreesToRadians(lat2);

    let a = sin(dLat / 2.0) * sin(dLat / 2.0) + sin(dLon / 2.0) * sin(dLon / 2.0) * cos(lat1) * cos(lat2);
    let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
    
    return earthRadiusKm * c;
}
