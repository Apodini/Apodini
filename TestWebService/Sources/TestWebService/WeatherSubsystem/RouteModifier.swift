//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Apodini
import Foundation
import NIO

extension Component {
    func asRoute() -> DelegationModifier<Self, TripWeatherRouteInitializer<Never>> {
        self.delegated(by: TripWeatherRouteInitializer())
    }
}

struct TripWeatherRouteInitializer<R: ResponseTransformable>: DelegatingHandlerInitializer {
    func instance<D>(for delegate: D) throws -> SomeHandler<R> where D: Handler {
        SomeHandler(TripWeatherBuildingHandler(delegate: Delegate(delegate, .required)))
    }
}

struct RouteSegment<I: Encodable>: Encodable {
    let date: Date
    let latitude: Double
    let longitude: Double
    let information: I
}

private struct TripWeatherBuildingHandler<H: Handler>: Handler {
    var delegate: Delegate<H>
    
    @Environment(\.connection) var connection
    
    @Environment(\.routeService) var route
    
    @Parameter var date = Date()
    
    @Parameter var startLatitude: Double
    @Parameter var startLongitude: Double
    
    @Parameter var endLatitude: Double
    @Parameter var endLongitude: Double
    
    
    func handle() async throws -> [RouteSegment<H.Response.Content>] {
        let route = try route(date, start: (startLatitude, startLongitude), end: (endLatitude, endLongitude))
        
        var response = [RouteSegment<H.Response.Content>]()
        
        for (date, location) in route {
            let handler = try delegate
                .environment(\WeatherComponent.date, date)
                .environment(\WeatherComponent.latitude, location.latitude)
                .environment(\WeatherComponent.longitude, location.longitude)
                .instance()
            
            if let partialResponse = try await handler.handle().transformToResponse(on: connection.eventLoop).get().content {
                response.append(RouteSegment(date: date,
                                             latitude: location.latitude,
                                             longitude: location.longitude,
                                             information: partialResponse))
            }
        }
        
        return response
    }
}
