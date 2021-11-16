//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import APNSwift

/// The `Payload` is used to configure plattform specific settings of a `Notification`.
public struct Payload {
    /// APNS specific payload.
    public let apnsPayload: APNSPayload?
    
    /// Initializer of a `Payload`.
    public init(apnsPayload: APNSPayload? = nil) {
        self.apnsPayload = apnsPayload
    }
}


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
    public let contentAvailable: Bool? // swiftlint:disable:this discouraged_optional_boolean
    /// The notification service app extension flag.
    public let mutableContent: Bool
    /// The type of a push notification.
    public let category: String?
    /// Groups push notifications together.
    public let threadID: String?
    
    /// Initializer of a `APNSPayload`.
    public init(
        badge: Int? = nil,
        sound: APNSwift.APNSwiftSoundType? = nil,
        contentAvailable: Bool? = nil, // swiftlint:disable:this discouraged_optional_boolean
        mutableContent: Bool = false,
        category: String? = nil,
        threadID: String? = nil
    ) {
        self.badge = badge
        self.sound = sound
        self.contentAvailable = contentAvailable
        self.mutableContent = mutableContent
        self.category = category
        self.threadID = threadID
    }
}
