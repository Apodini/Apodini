// swiftlint:disable force_unwrapping first_where
//
//  NotificationCenterTests.swift
//
//
//  Created by Alexander Collins on 03.12.20.
//

import XCTest
import struct Vapor.Abort
import Fluent
import FCM
import APNS
@testable import Apodini

final class NotificationCenterTests: ApodiniTests {
    var notificationCenter = NotificationCenter.shared

    override func setUp() {
        super.setUp()
        var notificationCenter = NotificationCenter.shared
        notificationCenter = EnvironmentValues.shared.notificationCenter
        notificationCenter.application = self.app
    }

    func testDeviceRegistration() throws {
        let topic = "test"
        let device = Device(id: "123", type: .apns, topics: [topic])
        let device2 = Device(id: "777", type: .fcm, topics: [topic])
        let device3 = Device(id: "888", type: .fcm)
        
        try notificationCenter.register(device: device).wait()
        try notificationCenter.register(device: device2).wait()
        try notificationCenter.register(device: device3).wait()
        
        let devices = try notificationCenter.getAllDevices().wait()
        let savedTopic = try Topic.query(on: app.db).filter(\.$name == topic).first().wait()
        let devicesOfTopic = try notificationCenter.getDevices(of: topic).wait()

        XCTAssert(devices.contains(device))
        XCTAssert(devices.contains(device2))
        XCTAssert(devices.contains(device3))
        XCTAssertNotNil(savedTopic)
        XCTAssert(devicesOfTopic.contains(device))
        XCTAssert(devicesOfTopic.contains(device2))
    }
    
    func testDeviceDeletion() throws {
        let topic = "test"
        let device = Device(id: "321", type: .apns, topics: [topic])
        
        notificationCenter.register(device: device)

        try notificationCenter.delete(device: device).wait()
        let devices = try notificationCenter.getAllDevices().wait()
            
        let devicesTopic = try notificationCenter.getDevices(of: topic).wait()
        
        XCTAssertFalse(devices.contains(device))
        XCTAssertFalse(devicesTopic.contains(device))
    }
    
    func testAddingTopicToDevice() throws {
        let topics = ["topic1", "topic2", "topic3"]
        let device = Device(id: "999", type: .apns)
        let device2 = Device(id: "000", type: .apns)
        
        try notificationCenter.register(device: device).wait()
        try notificationCenter.register(device: device2).wait()
        try notificationCenter.addTopics("topic1", "topic2", "topic3", to: device).wait()
        try notificationCenter.addTopics("topic1", to: device2).wait()
        let deviceReturn = try notificationCenter.getDevice(id: device.id).wait()
        let deviceTopics = deviceReturn.topics ?? []
        let devicesTopic = try notificationCenter.getDevices(of: "topic1").wait()

        XCTAssert(deviceTopics.sorted() == topics.sorted())
        XCTAssert(devicesTopic.contains(device))
        XCTAssert(devicesTopic.contains(device2))
    }
    
    func testRemovingTopicFromDevice() throws {
        let topic = "topic"
        let device = Device(id: "789", type: .apns, topics: [topic])
        
        try notificationCenter.register(device: device).wait()
        try notificationCenter.remove(topic: topic, from: device).wait()
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
        
        let retrievedAPNS = try notificationCenter.getAPNSDevices().wait()
        let retrievedFCM = try notificationCenter.getFCMDevices().wait()
        
        XCTAssert(retrievedAPNS == apnsDevices.map { Device(id: $0.id ?? "", type: $0.type) })
        XCTAssert(retrievedFCM == fcmDevices.map { Device(id: $0.id ?? "", type: $0.type) })
    }
    
    func testNotification() throws {
        let bird = Bird(name: "bird1", age: 2)
        
        let alert = Alert(title: "Title", subtitle: "Subtitle", body: "Body")
        let apnsPayload = APNSPayload(badge: 1, mutableContent: true, category: "general")
        let fcmPayload = FCMAndroidPayload(restrictedPackageName: "test", notification: FCMAndroidNotification(sound: "default"))
        let payload = Payload(apnsPayload: apnsPayload,
                              fcmAndroidPayload: fcmPayload)
        let notification = Notification(alert: alert, payload: payload)
        
        let apns = notification.transformToAPNS(with: bird)
        let dataAPNS = apns.data!.data(using: .utf8)!
        let decodedAPNS = try JSONDecoder().decode(Bird.self, from: dataAPNS)
        
        let fcm = notification.transformToFCM(with: bird)
        let dataFCM = fcm.data["data"]!.data(using: .utf8)!
        let decodedFCM = try JSONDecoder().decode(Bird.self, from: dataFCM)
        
        XCTAssert(decodedAPNS == bird)
        XCTAssert(apns.aps.badge == 1)
        XCTAssert(apns.aps.contentAvailable == 1)
        XCTAssert(decodedFCM == bird)
        XCTAssert(fcm.android?.priority == .high)
        XCTAssert(fcm.android?.ttl == "2419200s")
    }
}
// swiftlint:enable force_unwrapping first_where
