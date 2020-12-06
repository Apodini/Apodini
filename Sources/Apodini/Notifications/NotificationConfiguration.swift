//
//  File.swift
//  
//
//  Created by Alexander Collins on 06.12.20.
//

public struct Payload {
    public let apnsConfig: APNSConfig?
    public let fcmApnsConfig: FCMApnsConfig?
    public let fcmAndroidConfig: FCMAndroidConfig?
    public let fcmWebpushConfig: FCMWebpushConfig?
}

public struct APNSConfig {
    public let badge: Int?
    //    public let sound: APNSwift.APNSwiftSoundType?
    public let contentAvailable: Bool?
    public let mutableContent: Bool?
    public let category: String?
    public let threadID: String?
}

public struct FCMApnsConfig {
    public let headers: [String: String]
}

public struct FCMAndroidConfig {
    /// An identifier of a group of messages that can be collapsed, so that only the last message gets sent when delivery can be resumed.
    /// A maximum of 4 different collapse keys is allowed at any given time.
    public let collapse_key: String?
    
    /// The message priority
    //     public let priority: FCMAndroidMessagePriority
    
    
    /// The duration in seconds for which the notification should be kept in FCM storage while the device is offline.
    /// The default value is 4 weeks.
    /// 
    /// - Example: 3 seconds is encoded as `3s`
    public let ttl: String
    
    /// Package name of the application where the registration tokens must match in order to receive the message.
    public let restricted_package_name: String
}

public struct FCMWebpushConfig {
    public let headers: [String: String]
}
