// swiftlint:disable force_unwrapping first_where
//
//  NotificationCenterTests.swift
//
//
//  Created by Alexander Collins on 03.12.20.
//

import XCTest
import Vapor
import Fluent
@testable import Apodini


final class NotificationCenterTests: ApodiniTests {
    override func setUp() {
        super.setUp()
        NotificationCenter.shared.application = self.app
    }

    func testDeviceRegistration() throws {
        let topic = "test"
        let device = Device(id: "123", type: .apns, topics: [topic])
        
        NotificationCenter.shared.register(device: device)
        
        let devices = try NotificationCenter.shared.getAllDevices().wait()
        let savedTopic = try Topic.query(on: app.db).filter(\.$name == topic).first().wait()
        let devicesOfTopic = try NotificationCenter.shared.getDevices(of: topic).wait()

        XCTAssert(devices.contains(device))
        XCTAssertNotNil(savedTopic)
        XCTAssert(devicesOfTopic.contains(device))
    }
    
    func testDeviceDeletion() throws {
        let topic = "test"
        let device = Device(id: "321", type: .apns, topics: [topic])
        
        NotificationCenter.shared.register(device: device)

        try NotificationCenter.shared.delete(device: device).wait()
        let devices = try NotificationCenter.shared.getAllDevices().wait()
            
        let devicesTopic = try NotificationCenter.shared.getDevices(of: topic).wait()
        
        XCTAssertFalse(devices.contains(device))
        XCTAssertFalse(devicesTopic.contains(device))
    }
    
    func testAddingTopicToDevice() throws {
        let topics = ["topic1", "topic2", "topic3"]
        let device = Device(id: "999", type: .apns)
        
        try NotificationCenter.shared.register(device: device).wait()
        try NotificationCenter.shared.addTopics("topic1", "topic2", "topic3", to: device).wait()
        let deviceReturn = try NotificationCenter.shared.getDevice(id: device.id).wait()
        let deviceTopics = deviceReturn.topics ?? []

        XCTAssert(deviceTopics.sorted() == topics.sorted())
    }
    
    func testRemovingTopicFromDevice() throws {
        let topic = "topic"
        let device = Device(id: "789", type: .apns, topics: [topic])
        
        try NotificationCenter.shared.register(device: device).wait()
        try NotificationCenter.shared.remove(topic: topic, from: device).wait()
        let deviceReturn = try DeviceDatabaseModel
            .query(on: app.db)
            .filter(\.$id == device.id)
            .with(\.$topics)
            .first()
            .unwrap(or: Abort(.notFound))
            .wait()
            .transform()
 
        XCTAssertTrue(deviceReturn.topics!.isEmpty)
    }
    
    func testAPNSFCMRetrieval() throws {
        let apnsDevices = [
            DeviceDatabaseModel(id: "222", type: .apns),
            DeviceDatabaseModel(id: "333", type: .apns),
            DeviceDatabaseModel(id: "444", type: .apns)
        ]
        let fcmDevices = [
            DeviceDatabaseModel(id: "555", type: .fcm),
            DeviceDatabaseModel(id: "666", type: .fcm)
        ]
        let devices = apnsDevices + fcmDevices
        
        try devices.create(on: app.db).wait()
        
        let retrievedAPNS = try NotificationCenter.shared.getAPNSDevices().wait()
        let retrievedFCM = try NotificationCenter.shared.getFCMDevices().wait()
        
        XCTAssert(retrievedAPNS == apnsDevices.map { Device(id: $0.id ?? "", type: $0.type) })
        XCTAssert(retrievedFCM == fcmDevices.map { Device(id: $0.id ?? "", type: $0.type) })
    }
    
    func testNotification() throws {
        let bird = Bird(name: "bird1", age: 2)
        
        let notification = Notification(alert: Alert(title: "Title", subtitle: "Subtitle", body: "Body"))
        
        let apns = notification.transformToAPNS(with: bird)
        let dataAPNS = apns.data!.data(using: .utf8)!
        let decodedAPNS = try JSONDecoder().decode(Bird.self, from: dataAPNS)
        
        let fcm = notification.transformToFCM(with: bird)
        let dataFCM = fcm.data["data"]!.data(using: .utf8)!
        let decodedFCM = try JSONDecoder().decode(Bird.self, from: dataFCM)
        
        XCTAssert(decodedAPNS == bird)
        XCTAssert(decodedFCM == bird)
    }
}
// swiftlint:enable force_unwrapping first_where
