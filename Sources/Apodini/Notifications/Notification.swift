//
//  Notification.swift
//  
//
//  Created by Alexander Collins on 15.11.20.
//

import APNS
import FCM


//public struct Notification<T: Encodable>: APNSwiftNotification {
//    public var aps: APNSwiftPayload
//    public var data: T? = nil
//}


public struct Notification {
    public var alert: Alert
    public var payload: String?
    public var data: [String:String]?
    
    public init(alert: Alert) {
        self.alert = alert
    }
    
    public init(alert: Alert, payload: String?, data: [String:String]?) {
        self.alert = alert
        self.payload = payload
        self.data = data
    }
}

public struct Alert {
    public var title: String
    public var body: String
    
    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}
