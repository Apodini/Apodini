//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//       

// swiftlint:disable first_where

import XCTest
import XCTApodini
import FluentKit
import APNSwift
import Apodini
@testable import ApodiniNotifications
import XCTApodiniNetworking


final class NotificationCenterTests: XCTApodiniTest {
    override func setUpWithError() throws {
        try super.setUpWithError()
        try addMigrations(DeviceMigration())
    }

    func testDeviceRegistration() throws {
        let topic = "test"
        let device = Device(id: "123", type: .apns, topics: [topic])
        
        try app.notificationCenter.register(device: device).wait()
        
        let devices = try app.notificationCenter.getAllDevices().wait()
        let savedTopic = try Topic.query(on: app.database).filter(\.$name == topic).first().wait()
        let devicesOfTopic = try app.notificationCenter.getDevices(of: topic).wait()

        XCTAssert(devices.contains(device))
        XCTAssertNotNil(savedTopic)
        XCTAssert(devicesOfTopic.contains(device))
    }
    
    func testDeviceDeletion() throws {
        let topic = "test"
        let device = Device(id: "321", type: .apns, topics: [topic])
        
        // Try notFound
        XCTAssertThrowsError(try app.notificationCenter.delete(device: device).wait(), "Could not find device in database.")
        
        try app.notificationCenter.register(device: device).wait()

        try app.notificationCenter.delete(device: device).wait()
        let devices = try app.notificationCenter.getAllDevices().wait()
            
        let devicesTopic = try app.notificationCenter.getDevices(of: topic).wait()
        
        XCTAssertFalse(devices.contains(device))
        XCTAssertFalse(devicesTopic.contains(device))
    }
    
    func testAddingTopicToDevice() throws {
        let topics = ["topic1", "topic2", "topic3"]
        let device = Device(id: "999", type: .apns)
        let device2 = Device(id: "000", type: .apns)
        
        try app.notificationCenter.register(device: device).wait()
        try app.notificationCenter.register(device: device2).wait()
        try app.notificationCenter.addTopics("topic1", "topic2", "topic3", to: device).wait()
        // Check if .unique on topics constraint isn't violated
        try app.notificationCenter.addTopics("topic1", "topic2", "topic3", to: device).wait()
        try app.notificationCenter.addTopics("topic1", to: device2).wait()
        let deviceReturn = try app.notificationCenter.getDevice(id: device.id).wait()
        let deviceTopics = deviceReturn.topics ?? []
        let devicesTopic = try app.notificationCenter.getDevices(of: "topic1").wait()

        XCTAssert(deviceTopics.sorted() == topics.sorted())
        XCTAssert(devicesTopic.contains(device))
        XCTAssert(devicesTopic.contains(device2))
    }
    
    func testRemovingTopicFromDevice() throws {
        let topic = "topic"
        let device = Device(id: "789", type: .apns, topics: [topic])
        
        // Check
        XCTAssertThrowsError(try app.notificationCenter.remove(topic: topic, from: device).wait())
        
        let device2 = Device(id: "010", type: .apns, topics: [topic])
        try app.notificationCenter.register(device: device2).wait()
        
        XCTAssertThrowsError(try app.notificationCenter.remove(topic: topic, from: device).wait())
        try app.notificationCenter.register(device: device).wait()
        
        try app.notificationCenter.addTopics(topic, to: device).wait()
        try app.notificationCenter.remove(topic: topic, from: device).wait()
        let deviceReturn = try DeviceDatabaseModel
            .query(on: app.database)
            .filter(\.$id == device.id)
            .with(\.$topics)
            .first()
            .unwrap(or: LKHTTPAbortError(status: .notFound))
            .wait()
            .transform()
 
        let topics = try XCTUnwrap(deviceReturn.topics)
        XCTAssertTrue(topics.isEmpty)
    }
    
    func testAPNSRetrieval() throws {
        let apnsDevices = [
            DeviceDatabaseModel(id: "222", type: .apns),
            DeviceDatabaseModel(id: "333", type: .apns),
            DeviceDatabaseModel(id: "444", type: .apns)
        ]
        let devices = apnsDevices
        
        try devices.create(on: app.database).wait()
        
        let retrievedAPNS = try app.notificationCenter.getAPNSDevices().wait()
        XCTAssert(retrievedAPNS == apnsDevices.map { Device(id: $0.id ?? "", type: $0.type) })
    }
    
    func testDeviceRetrievalFromTopic() throws {
        // Test topic not found
        XCTAssertThrowsError(try app.notificationCenter.getAPNSDevices(of: "test").wait())
        
        let device = Device(id: "999", type: .apns, topics: ["test"])
        try app.notificationCenter.register(device: device).wait()
        
        var apnsDevices = try app.notificationCenter.getAPNSDevices(of: "test").wait()
        XCTAssertEqual(apnsDevices, [device])
        
        let device2 = Device(id: "888", type: .apns, topics: ["test"])
        let device3 = Device(id: "777", type: .apns, topics: ["all"])
        let device4 = Device(id: "666", type: .apns, topics: ["test"])
        
        try app.notificationCenter.register(device: device2).wait()
        try app.notificationCenter.register(device: device3).wait()
        try app.notificationCenter.register(device: device4).wait()

        apnsDevices = try app.notificationCenter.getAPNSDevices(of: "test").wait()
        
        // Test correct retrieval
        XCTAssertEqual(apnsDevices, [device, device2, device4])
    }
    
    func testNotificationWithData() throws {
        let bird = Bird(name: "bird1", age: 2)
        
        let alert = Alert(title: "Title", subtitle: "Subtitle", body: "Body")
        let apnsPayload = APNSPayload(badge: 1, mutableContent: true, category: "general")
        let payload = Payload(apnsPayload: apnsPayload)
        let notification = Notification(alert: alert, payload: payload)
        
        let apnsWithData = notification.transformToAPNS(with: bird)
        let dataAPNS = try XCTUnwrap(apnsWithData.data?.data(using: .utf8))
        let decodedAPNS = try JSONDecoder().decode(Bird.self, from: dataAPNS)
        
        XCTAssert(decodedAPNS == bird)
        XCTAssert(apnsWithData.aps.badge == 1)
        XCTAssert(apnsWithData.aps.contentAvailable == 1)
        
        let apnsWithoutData = notification.transformToAPNS()
        XCTAssert(apnsWithoutData.aps.contentAvailable == 0)
        XCTAssert(apnsWithoutData.aps.badge == 1)
        
        let apnsAlert = try XCTUnwrap(apnsWithoutData.aps.alert)
        XCTAssert(apnsAlert.title == alert.title)
        XCTAssert(apnsAlert.subtitle == alert.subtitle)
        XCTAssert(apnsAlert.body == alert.body)
    }
    
    func testDeviceEquatable() throws {
        let device = Device(id: "1", type: .apns)
        let devicedatabaseModel = DeviceDatabaseModel(id: "1", type: .apns)
        let topic = Topic(name: "1")
        
        XCTAssert(device == Device(id: "1", type: .apns))
        XCTAssertFalse(device == Device(id: "2", type: .apns))
        XCTAssert(devicedatabaseModel == DeviceDatabaseModel(id: "1", type: .apns))
        XCTAssertFalse(devicedatabaseModel == DeviceDatabaseModel(id: "2", type: .apns))
        XCTAssert(topic == Topic(name: "1"))
        XCTAssertFalse(topic == Topic(name: "2"))
    }
}
// swiftlint:enable first_where
