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
    
    /// Initializer of a `Payload`.
    public init(apnsPayload: APNSPayload? = nil,
                fcmAndroidPayload: FCMAndroidPayload? = nil,
                fcmWebpushPayload: FCMWebpushPayload? = nil) {
        self.apnsPayload = apnsPayload
        self.fcmAndroidPayload = fcmAndroidPayload
        self.fcmWebpushPayload = fcmWebpushPayload
    }
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
    
    /// Initializer of a `APNSPayload`.
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
    /// The default priority is `high`.
    public let priority: FCMAndroidMessagePriority?
    
    /// The duration in seconds for which the notification should be kept in FCM storage while the device is offline.
    /// The default value is 4 weeks.
    /// 
    /// - Example: 3 seconds is encoded as `3s`.
    public let ttl: String?
    
    /// Package name of the application where the registration tokens must match in order to receive the message.
    public let restrictedPackageName: String
    
    /// Notification to send to android devices.
    public let notification: FCMAndroidNotification
    
    /// Initializer of a `FCMAndroidPayload`.
    public init(collapseKey: String? = nil,
                priority: FCMAndroidMessagePriority? = nil,
                ttl: String? = nil,
                restrictedPackageName: String,
                notification: FCMAndroidNotification) {
        self.collapseKey = collapseKey
        self.priority = priority
        self.ttl = ttl
        self.restrictedPackageName = restrictedPackageName
        self.notification = notification
    }
    
    internal func transform() -> FCMAndroidConfig {
        FCMAndroidConfig(collapse_key: collapseKey,
                         priority: priority ?? .high,
                         ttl: ttl ?? "2419200s",
                         restricted_package_name: restrictedPackageName,
                         notification: notification)
    }
}

// swiftlint:disable discouraged_optional_collection
/// FCM specific payload for Web Push.
public struct FCMWebpushPayload {
    /// Web Push specific headers as a dictionary.
    public let headers: [String: String]?
    
    /// Web Notification options as a JSON object.
    /// If present will override the default `Alert`.
    public var notification: [String: String]?
    
    /// Initializer of a `FCMWebpushPayload`.
    public init(headers: [String: String]? = nil, notification: [String: String]? = nil) {
        self.headers = notification
        self.notification = notification
    }
    
    internal func transform() -> FCMWebpushConfig {
        FCMWebpushConfig(headers: headers, notification: notification)
    }
}
// swiftlint:enable discouraged_optional_collection
