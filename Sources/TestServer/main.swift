//
//  TestRESTServer.swift
//  
//
//  Created by Paul Schmiedmayer on 7/6/20.
//

import Apodini
import Vapor
import NIO


struct TestServer: Apodini.Server {
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
        
        @Body
        var device: Device
        
        func handle() -> EventLoopFuture<HTTPStatus> {
            notificationCenter.send(notification: .init(title: "Test"), device: device).map { .ok }
        }
    }

    
    var content: some Component {
        Group("test") {
             Hello()
        }
        Text("Hello World! 👋")
            .response(EmojiMediator(emojis: "🎉"))
            .response(EmojiMediator())
            .guard(PrintGuard())
            .schedule(TestJob())
        Group("swift") {
            TestComponent()
            Text("Hello Swift! 💻")
                .response(EmojiMediator())
                .guard(PrintGuard())
        }.guard(PrintGuard("Someone is accessing Swift 😎!!")).httpMethod(.POST)
        Group("test") {
            Text("Hello Swift! 💻")
        }
    }
    
    var configuration: some Configuration {
        APNSConfiguration(.pem(pemPath: "/Users/awocatmac/Developer/Action Based Events Sample/backend/Certificates/apns.pem"),
                                  topic: "de.tum.in.www1.ios.Action-Based-Events-Sample",
                                  environment: .sandbox)

    }
}

TestServer.main()
