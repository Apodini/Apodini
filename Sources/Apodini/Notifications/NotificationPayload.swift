//
//  File.swift
//  
//
//  Created by Alexander Collins on 06.12.20.
//
import APNS
import FCM

public struct Payload {
    public let apnsPayload: APNSPayload?
    public let fcmAndroidPayload: FCMAndroidPayload?
    public let fcmWebpushPayload: FCMWebpushPayload?
}

// swiftlint:disable discouraged_optional_boolean
public struct APNSPayload {
    public let badge: Int?
    public let sound: APNSwift.APNSwiftSoundType?
    public let contentAvailable: Bool?
    public let mutableContent: Bool
    public let category: String?
    public let threadID: String?
    
    public init(badge: Int? = nil,
                sound: APNSwift.APNSwiftSoundType? = nil,
                contentAvailable: Bool? = nil,
                mutableContent: Bool = false,
                category: String? = nil,
                threadID: String? = nil) {
        self.badge = badge
        self.sound = sound
        self.contentAvailable = contentAvailable
        self.mutableContent = mutableContent
        self.category = category
        self.threadID = threadID
    }
}
// swiftlint:enable discouraged_optional_boolean

public struct FCMAndroidPayload {
    /// An identifier of a group of messages that can be collapsed, so that only the last message gets sent when delivery can be resumed.
    /// A maximum of 4 different collapse keys is allowed at any given time.
    public let collapseKey: String?
    
    /// The priority of a message.
    /// This can either be `normal` or `high`.
    /// The default priority is `high`
    public let priority: FCMAndroidMessagePriority
    
    /// The duration in seconds for which the notification should be kept in FCM storage while the device is offline.
    /// The default value is 4 weeks.
    /// 
    /// - Example: 3 seconds is encoded as `3s`
    public let ttl: String
    
    /// Package name of the application where the registration tokens must match in order to receive the message.
    public let restrictedPackageName: String
    
    /// Notification to send to android devices.
    public var notification: FCMAndroidNotification
    
    internal func transform() -> FCMAndroidConfig {
        FCMAndroidConfig(collapse_key: collapseKey,
                         priority: priority,
                         ttl: ttl,
                         restricted_package_name: restrictedPackageName,
                         notification: notification)
    }
}

public struct FCMWebpushPayload {
    public let headers: [String: String]
    
    internal func transform() -> FCMWebpushConfig {
        FCMWebpushConfig(headers: headers)
    }
}
