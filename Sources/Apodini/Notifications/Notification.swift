//
//  Notification.swift
//  
//
//  Created by Alexander Collins on 15.11.20.
//

import APNS
import FCM
import Foundation

public struct Notification {
    public let alert: Alert
    public let payload: Payload?
    
    public init(alert: Alert, payload: Payload? = nil) {
        self.alert = alert
        self.payload = payload
    }
}

extension Notification {
    internal func transformToAPNS() -> AcmeNotification {
        let apnsPayload = generateAPNSwiftPayload(hasData: false)
        
        return AcmeNotification(aps: apnsPayload)
    }
    
    internal func transformToAPNS<T: Encodable>(with data: T) -> AcmeNotification {
        let apnsPayload = generateAPNSwiftPayload(hasData: true)
        let json = convertToJSON(data)
        
        return AcmeNotification(aps: apnsPayload, data: json)
    }
    
    private func generateAPNSwiftPayload(hasData: Bool) -> APNSwiftPayload {
        let apnsAlert = APNSwiftAlert.init(title: alert.title, subtitle: alert.subtitle, body: alert.body)
        let apnsConfig = payload?.apnsConfig
        
        return APNSwiftPayload(alert: apnsAlert,
                               badge: apnsConfig?.badge,
                               sound: nil,
                               hasContentAvailable: apnsConfig?.contentAvailable ?? hasData,
                               hasMutableContent: apnsConfig?.mutableContent ?? false,
                               category: apnsConfig?.category,
                               threadID: apnsConfig?.threadID)
    }
    
    internal func transformToFCM() -> FCMMessageDefault {
        let fcmAlert = FCMNotification(title: alert.title ?? "", body: alert.body ?? "")
        
        return FCMMessageDefault(notification: fcmAlert)
    }
    
    internal func transformToFCM<T: Encodable>(with data: T) -> FCMMessageDefault {
        let fcmAlert = FCMNotification(title: alert.title ?? "", body: alert.body ?? "")
        let json = convertToJSON(data)
        let dict = ["data": json]
        
        return FCMMessageDefault(notification: fcmAlert, data: dict)
    }
    
    private func convertToJSON<T: Encodable>(_ object: T) -> String {
        guard let json = try? JSONEncoder().encode(object) else {
            fatalError("Cannot convert \(object) to JSON")
        }
        return String(decoding: json, as: UTF8.self)
    }
}

public struct Alert {
    public let title: String?
    public let subtitle: String?
    public let body: String?
    
    public init(title: String? = nil, subtitle: String? = nil, body: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.body = body
    }
}

internal struct AcmeNotification: APNSwiftNotification {
    let aps: APNSwiftPayload
    let data: String?
    
    init(aps: APNSwiftPayload, data: String? = nil) {
        self.aps = aps
        self.data = data
    }
}
