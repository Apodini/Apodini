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
import FCM
import APNSwift
import Apodini
@testable import ApodiniNotifications
import XCTApodiniNetworking


final class NotificationCenterTests: XCTApodiniTest {
    override func setUpWithError() throws {
        try super.setUpWithError()
        try super.addMigrations(DeviceMigration())
    }

    func testDeviceRegistration() throws {
        let topic = "test"
        let device = Device(id: "123", type: .apns, topics: [topic])
        let device2 = Device(id: "777", type: .fcm, topics: [topic])
        let device3 = Device(id: "888", type: .fcm)
        
        try app.notificationCenter.register(device: device).wait()
        try app.notificationCenter.register(device: device2).wait()
        try app.notificationCenter.register(device: device3).wait()
        
        let devices = try app.notificationCenter.getAllDevices().wait()
        let savedTopic = try Topic.query(on: app.database).filter(\.$name == topic).first().wait()
        let devicesOfTopic = try app.notificationCenter.getDevices(of: topic).wait()

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
            //.unwrap(or: Abort(.notFound))
            .unwrap(or: LKHTTPAbortError(status: .notFound))
            .wait()
            .transform()
 
        let topics = try XCTUnwrap(deviceReturn.topics)
        XCTAssertTrue(topics.isEmpty)
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
        
        try devices.create(on: app.database).wait()
        
        let retrievedAPNS = try app.notificationCenter.getAPNSDevices().wait()
        let retrievedFCM = try app.notificationCenter.getFCMDevices().wait()
        
        XCTAssert(retrievedAPNS == apnsDevices.map { Device(id: $0.id ?? "", type: $0.type) })
        XCTAssert(retrievedFCM == fcmDevices.map { Device(id: $0.id ?? "", type: $0.type) })
    }
    
    func testDeviceRetrievalFromTopic() throws {
        // Test topic not found
        XCTAssertThrowsError(try app.notificationCenter.getAPNSDevices(of: "test").wait())
        XCTAssertThrowsError(try app.notificationCenter.getFCMDevices(of: "test").wait())
        
        let device = Device(id: "999", type: .apns, topics: ["test"])
        try app.notificationCenter.register(device: device).wait()
        
        var apnsDevices = try app.notificationCenter.getAPNSDevices(of: "test").wait()
        // Test empty retrieval
        var fcmDevices = try app.notificationCenter.getFCMDevices(of: "test").wait()
        
        XCTAssertEqual(apnsDevices, [device])
        XCTAssertEqual(fcmDevices, [])
        
        let device2 = Device(id: "888", type: .apns, topics: ["test"])
        let device3 = Device(id: "777", type: .apns, topics: ["all"])
        let device4 = Device(id: "666", type: .apns, topics: ["test"])
        let device5 = Device(id: "555", type: .fcm, topics: ["test"])
        let device6 = Device(id: "444", type: .fcm)
        
        try app.notificationCenter.register(device: device2).wait()
        try app.notificationCenter.register(device: device3).wait()
        try app.notificationCenter.register(device: device4).wait()
        try app.notificationCenter.register(device: device5).wait()
        try app.notificationCenter.register(device: device6).wait()

        apnsDevices = try app.notificationCenter.getAPNSDevices(of: "test").wait()
        fcmDevices = try app.notificationCenter.getFCMDevices(of: "test").wait()
        
        // Test correct retrieval
        XCTAssertEqual(apnsDevices, [device, device2, device4])
        XCTAssertEqual(fcmDevices, [device5])
    }
    
    func testNotificationWithData() throws {
        let bird = Bird(name: "bird1", age: 2)
        
        let alert = Alert(title: "Title", subtitle: "Subtitle", body: "Body")
        let apnsPayload = APNSPayload(badge: 1, mutableContent: true, category: "general")
        let fcmAndroidPayload = FCMAndroidPayload(restrictedPackageName: "test", notification: FCMAndroidNotification(sound: "default"))
        let fcmWebpushPayload = FCMWebpushPayload(headers: ["key": "value"])
        let payload = Payload(apnsPayload: apnsPayload,
                              fcmAndroidPayload: fcmAndroidPayload,
                              fcmWebpushPayload: fcmWebpushPayload)
        let notification = Notification(alert: alert, payload: payload)
        
        let apnsWithData = notification.transformToAPNS(with: bird)
        let dataAPNS = try XCTUnwrap(apnsWithData.data?.data(using: .utf8))
        let decodedAPNS = try JSONDecoder().decode(Bird.self, from: dataAPNS)
        
        let fcmWithData = notification.transformToFCM(with: bird)
        let dataFCM = try XCTUnwrap(fcmWithData.data["data"]?.data(using: .utf8))
        let decodedFCM = try JSONDecoder().decode(Bird.self, from: dataFCM)
        
        XCTAssert(decodedAPNS == bird)
        XCTAssert(apnsWithData.aps.badge == 1)
        XCTAssert(apnsWithData.aps.contentAvailable == 1)
        
        XCTAssert(decodedFCM == bird)
        XCTAssert(fcmWithData.android?.priority == .high)
        XCTAssert(fcmWithData.android?.ttl == "2419200s")
        XCTAssert(fcmWithData.android?.restricted_package_name == fcmAndroidPayload.restrictedPackageName)
        XCTAssert(fcmWithData.android?.notification == fcmAndroidPayload.notification)
        XCTAssert(fcmWithData.webpush?.headers == fcmWebpushPayload.headers)
        
        let apnsWithoutData = notification.transformToAPNS()
        let fcmWithoutData = notification.transformToFCM()
        
        XCTAssert(apnsWithoutData.aps.contentAvailable == 0)
        XCTAssert(apnsWithoutData.aps.badge == 1)
        
        let apnsAlert = try XCTUnwrap(apnsWithoutData.aps.alert)
        XCTAssert(apnsAlert.title == alert.title)
        XCTAssert(apnsAlert.subtitle == alert.subtitle)
        XCTAssert(apnsAlert.body == alert.body)
        
        XCTAssert(fcmWithoutData.android?.priority == .high)
        XCTAssert(fcmWithoutData.android?.ttl == "2419200s")
        XCTAssert(fcmWithoutData.android?.restricted_package_name == fcmAndroidPayload.restrictedPackageName)
        XCTAssert(fcmWithoutData.android?.notification == fcmAndroidPayload.notification)
        XCTAssert(fcmWithoutData.webpush?.headers == fcmWebpushPayload.headers)
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
