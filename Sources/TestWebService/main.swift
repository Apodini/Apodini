//
//  TestWebService.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini
import Vapor
import NIO


struct TestWebService: Apodini.WebService {
    struct PrintGuard: SyncGuard {
        private let message: String?
        @Apodini.Request
        var request: Vapor.Request
        
        
        init(_ message: String? = nil) {
            self.message = message
        }
        
        
        func check() {
            request.logger.info("\(message?.description ?? request.description)")
        }
    }
    
    struct EmojiMediator: ResponseTransformer {
        private let emojis: String
        
        
        init(emojis: String = "✅") {
            self.emojis = emojis
        }
        
        
        func transform(response: String) -> String {
            "\(emojis) \(response) \(emojis)"
        }
    }
    
    struct Hello: Component {
        @Apodini.Environment(\.notificationCenter) var notificationCenter: Apodini.NotificationCenter
        
        func handle() -> EventLoopFuture<HTTPStatus> {
            let notify = Notification(alert: .init(title: "Hey", body: "Test"))
            let data = TestStruct(string: "Test", int: 2)
            return notificationCenter.send(notification: notify, with: data, to: "test").transform(to: .ok)
        }
    }
    
    struct RegisterAPNS: Component {
        @Apodini.Environment(\.notificationCenter) var notificationCenter: Apodini.NotificationCenter
        
        @Body
        var device: Device
        
        func handle() -> EventLoopFuture<HTTPStatus> {
            notificationCenter.register(device: device).transform(to: .ok)
        }
    }
    
    struct AddTopic: Component {
        @Apodini.Environment(\.notificationCenter) var notificationCenter: Apodini.NotificationCenter

        func handle() -> EventLoopFuture<HTTPStatus> {
            notificationCenter.getFCMDevices().flatMap { devices -> EventLoopFuture<Void> in
                let device = devices[0]
                return notificationCenter.addTopics("test", to: device)
            }.map { .ok }
        }
    }
    
    
    var content: some Component {
        RegisterAPNS().operation(.create)
        Group("send") {
            Hello()
        }
        Group("topic") {
            AddTopic()
        }
        
    }
    
    var configuration: Configuration {
        APNSConfiguration(.pem(pemPath: "/Users/awocatmac/Developer/Action Based Events Sample/backend/Certificates/apns.pem"),
                          topic: "de.tum.in.www1.ios.Action-Based-Events-Sample",
                          environment: .sandbox)
        FCMConfiguration("/Users/awocatmac/Developer/Action Based Events Sample/backend/Certificates/fcm.json")
        DatabaseConfiguration(.defaultMongoDB("mongodb://localhost:27017/apodini_db"))
            .addNotifications()
    }
}

TestWebService.main()

struct TestStruct: Codable {
    let string: String
    let int: Int
}
