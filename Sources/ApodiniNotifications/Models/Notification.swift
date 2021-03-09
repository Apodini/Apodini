import APNSwift
import FCM
import Foundation

/// A struct to create push notifications which can be sent to APNS and FCM.
public struct Notification {
    /// Visual message of a `Notification` which can be used across all plattforms.
    public let alert: Alert?
    /// Configuration of a `Notification` for every plattform.
    public let payload: Payload?
    
    /// Initializer of a `Notification`.
    public init(alert: Alert? = nil, payload: Payload? = nil) {
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
        var apnsAlert: APNSwiftAlert?
        if let alert = alert {
            apnsAlert = APNSwiftAlert(title: alert.title, subtitle: alert.subtitle, body: alert.body)
        }
        let apnsConfig = payload?.apnsPayload
        
        return APNSwiftPayload(alert: apnsAlert,
                               badge: apnsConfig?.badge,
                               sound: apnsConfig?.sound,
                               hasContentAvailable: apnsConfig?.contentAvailable ?? hasData,
                               hasMutableContent: apnsConfig?.mutableContent ?? false,
                               category: apnsConfig?.category,
                               threadID: apnsConfig?.threadID)
    }
    
    internal func transformToFCM() -> FCMMessageDefault {
        let fcmAlert = FCMNotification(title: alert?.title ?? "", body: alert?.body ?? "")
        
        return FCMMessage(notification: fcmAlert,
                          android: payload?.fcmAndroidPayload?.transform(),
                          webpush: payload?.fcmWebpushPayload?.transform())
    }
    
    internal func transformToFCM<T: Encodable>(with data: T) -> FCMMessageDefault {
        let fcmAlert = FCMNotification(title: alert?.title ?? "", body: alert?.body ?? "")
        let json = convertToJSON(data)
        let dict = ["data": json]
        
        return FCMMessage(notification: fcmAlert,
                          data: dict,
                          android: payload?.fcmAndroidPayload?.transform(),
                          webpush: payload?.fcmWebpushPayload?.transform())
    }
    
    private func convertToJSON<T: Encodable>(_ object: T) -> String {
        guard let json = try? JSONEncoder().encode(object) else {
            fatalError("Cannot convert \(object) to JSON")
        }
        return String(decoding: json, as: UTF8.self)
    }
}

/// The message of a push notifications which can be used across all plattforms.
public struct Alert {
    /// The title of a push notification.
    public let title: String?
    
    /// The subtitle of a push notification.
    /// This field is only used by APNS.
    public let subtitle: String?
    
    /// The body of a push notification
    public let body: String?
    
    /// Initializer of a `Notification`
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
