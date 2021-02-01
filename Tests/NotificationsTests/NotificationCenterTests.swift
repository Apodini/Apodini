// swiftlint:disable first_where
import XCTest
import XCTApodini
import Fluent
import FCM
import APNS
import XCTVapor
import Apodini
@testable import Notifications

final class NotificationCenterTests: XCTApodiniTest {
    var notificationCenter = NotificationCenter.shared
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        try super.addMigrations(DeviceMigration())
        
        notificationCenter.application = self.app
    }
    
    func testMissingApplication() throws {
        notificationCenter.application = nil
        
        XCTAssertRuntimeFailure(try? self.notificationCenter.getAllDevices().wait(),
                                "Fatal error: The `NotificationCenter` is not configured. Please add the missing configuration to the web service.")
    }
    
    func testEnvironmentValue() throws {
        let value = Apodini.Environment(\.notificationCenter).wrappedValue
        
        XCTAssertNotNil(value)
        XCTAssertNotNil(value.application)
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
        
        // Try notFound
        XCTAssertThrowsError(try notificationCenter.delete(device: device).wait(), "Could not find device in database.")
        
        try notificationCenter.register(device: device).wait()

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
        // Check if .unique on topics constraint isn't violated
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
        
        // Check
        XCTAssertThrowsError(try notificationCenter.remove(topic: topic, from: device).wait())
        
        let device2 = Device(id: "010", type: .apns, topics: [topic])
        try notificationCenter.register(device: device2).wait()
        
        XCTAssertThrowsError(try notificationCenter.remove(topic: topic, from: device).wait())
        try notificationCenter.register(device: device).wait()
        
        try notificationCenter.addTopics(topic, to: device).wait()
        try notificationCenter.remove(topic: topic, from: device).wait()
        let deviceReturn = try DeviceDatabaseModel
            .query(on: app.db)
            .filter(\.$id == device.id)
            .with(\.$topics)
            .first()
            .unwrap(or: Abort(.notFound))
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
        
        try devices.create(on: app.db).wait()
        
        let retrievedAPNS = try notificationCenter.getAPNSDevices().wait()
        let retrievedFCM = try notificationCenter.getFCMDevices().wait()
        
        XCTAssert(retrievedAPNS == apnsDevices.map { Device(id: $0.id ?? "", type: $0.type) })
        XCTAssert(retrievedFCM == fcmDevices.map { Device(id: $0.id ?? "", type: $0.type) })
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
        let deviceDbModel = DeviceDatabaseModel(id: "1", type: .apns)
        let topic = Topic(name: "1")
        
        XCTAssert(device == Device(id: "1", type: .apns))
        XCTAssertFalse(device == Device(id: "2", type: .apns))
        XCTAssert(deviceDbModel == DeviceDatabaseModel(id: "1", type: .apns))
        XCTAssertFalse(deviceDbModel == DeviceDatabaseModel(id: "2", type: .apns))
        XCTAssert(topic == Topic(name: "1"))
        XCTAssertFalse(topic == Topic(name: "2"))
    }
}
// swiftlint:enable first_where
