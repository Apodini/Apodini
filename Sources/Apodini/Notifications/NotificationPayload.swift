//
//  File.swift
//  
//
//  Created by Alexander Collins on 06.12.20.
//
import APNS
import FCM

/// The `Payload` is used to configure plattform specific settings of a `Notification`.
public struct Payload {
    /// APNS specific payload.
    public let apnsPayload: APNSPayload?
    /// FCM Android specific payload.
    public let fcmAndroidPayload: FCMAndroidPayload?
    /// FCM Web Push specific payload.
    public let fcmWebpushPayload: FCMWebpushPayload?
}

// swiftlint:disable discouraged_optional_boolean

/// APNS specific payload with app-specifc information.
///
/// - Remark: More information on APNS payload: [Apple](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/generating_a_remote_notification)
public struct APNSPayload {
    /// Modifes the badge of an app icon.
    public let badge: Int?
    /// The sound to play when receiving a push notification.
    public let sound: APNSwift.APNSwiftSoundType?
    /// Enables background updates of push notifications.
    /// This value is set to true when sending background data with the `NotificationCenter`.
    public let contentAvailable: Bool?
    /// The notification service app extension flag.
    public let mutableContent: Bool
    /// The type of a push notification.
    public let category: String?
    /// Groups push notifications together.
    public let threadID: String?
    
    /// Initializer of a `APNSPayload`
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
/// FCM specific payload for Android devices.
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
    public let notification: FCMAndroidNotification
    
    internal func transform() -> FCMAndroidConfig {
        FCMAndroidConfig(collapse_key: collapseKey,
                         priority: priority,
                         ttl: ttl,
                         restricted_package_name: restrictedPackageName,
                         notification: notification)
    }
}

/// FCM specific payload for Web Push..
public struct FCMWebpushPayload {
    /// Web Push specific headers as a dictionary.
    public let headers: [String: String]
    
    internal func transform() -> FCMWebpushConfig {
        FCMWebpushConfig(headers: headers)
    }
}
