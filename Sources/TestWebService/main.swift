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
    
    struct TestComponent: Component {
        
        @Body
        var device: Device
        
        @APNSNotification
        var notification: ApodiniAPNS
        
        func handle() -> EventLoopFuture<HTTPStatus> {
            notification
                .send(.init(title: "Test"), to: device.deviceID)
                .map { .ok }
            
        }
    }
    
    struct TestJob: Job {
        var expression = "*/1 * * * *"
        
        func task() {
            print("Hello World")
        }
    }
    
    struct Hello: Component {
        @Apodini.Environment(\.notificationCenter) var notificationCenter: Apodini.NotificationCenter
        
        func handle() -> HTTPStatus {
            notificationCenter.send(notification: .init(alert: .init(title: "Hey", body: "Test")), to: "test")
            return HTTPStatus.ok
        }
    }
    
    struct RegisterAPNS: Component {
        @Apodini.Environment(\.notificationCenter) var notificationCenter: Apodini.NotificationCenter
        
        @Body
        var device: Device
        
        func handle() -> HTTPStatus {
            notificationCenter.register(device)
            return HTTPStatus.ok
        }
    }
    
    
    var content: some Component {
        Group("register") {
            RegisterAPNS()
        }.httpMethod(.POST)
        Group("send") {
            Hello()
        }
        
    }
    
    var configuration: some Configuration {
        APNSConfiguration(.pem(pemPath: "/Users/awocatmac/Developer/Action Based Events Sample/backend/Certificates/apns.pem"),
                          topic: "de.tum.in.www1.ios.Action-Based-Events-Sample",
                          environment: .sandbox)
        FCMConfiguration("/Users/awocatmac/Downloads/server-side-swift-282e3-firebase-adminsdk-el7gq-4bd40d5e3a.json")
        
    }
}

TestWebService.main()
