//
//  Notification.swift
//  
//
//  Created by Alexander Collins on 15.11.20.
//

import APNS


public struct Notification<T: Encodable>: APNSwiftNotification {
    public var aps: APNSwiftPayload
    public var data: T
}

