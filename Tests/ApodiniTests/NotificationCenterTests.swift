//
//  NotificationCenterTests.swift
//
//
//  Created by Alexander Collins on 03.12.20.
//

import XCTest
import NIO
import Vapor
import Fluent
@testable import Apodini


final class NotificationCenterTests: ApodiniTests {
    struct AddDevicesComponent: Component {
        @Apodini.Environment(\.notificationCenter)
        var notificationCenter: Apodini.NotificationCenter
        
        @Parameter
        var device: Device
        
        func handle() -> EventLoopFuture<HTTPStatus> {
            notificationCenter.register(device: device).map { .ok }
        }
    }
    
    struct RetrieveDevicesComponent: Component {
        @Apodini.Environment(\.notificationCenter)
        var notificationCenter: Apodini.NotificationCenter
        
        func handle() -> EventLoopFuture<[Device]> {
            notificationCenter.getAllDevices()
        }
    }
    
    func testDeviceUniqueness() throws {
        let device = Device(id: "123", type: .apns)
        let deviceData = ByteBuffer(data: try JSONEncoder().encode(device))
        
        NotificationCenter.shared.application = app
        
        let request = Request(application: app, collectedBody: deviceData, on: app.eventLoopGroup.next())
        
        _ = try request
            .enterRequestContext(with: AddDevicesComponent(), using: RESTSemanticModelBuilder(app)) { component in
                component.handle().encodeResponse(for: request)
            }
            .wait()
        
        _ = try request
            .enterRequestContext(with: AddDevicesComponent(), using: RESTSemanticModelBuilder(app)) { component in
                component.handle().encodeResponse(for: request)
            }
            .wait()
        
        let response = try request
            .enterRequestContext(with: RetrieveDevicesComponent(), using: RESTSemanticModelBuilder(app)) { component in
                component.handle().encodeResponse(for: request)
            }
            .wait()
        
        let responseData = try XCTUnwrap(response.body.data)
        let responseDevices = try JSONDecoder().decode([Device].self, from: responseData)
        XCTAssert(responseDevices.count == 1)
    }
}
