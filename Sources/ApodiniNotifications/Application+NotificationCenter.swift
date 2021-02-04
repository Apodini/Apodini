import Apodini

extension Application {
    /// Holds the `NotificationCenter` of the web service.
    public var notificationCenter: NotificationCenter {
        if let storedNotificationCenter = self.storage[NotificationCenterKey.self] {
            return storedNotificationCenter
        }
        let newNotificationCenter = NotificationCenter(app: self)
        self.storage[NotificationCenterKey.self] = newNotificationCenter
        
        return newNotificationCenter
    }
    
    struct NotificationCenterKey: StorageKey {
        typealias Value = NotificationCenter
    }
}
