import Apodini

extension Application {
    /// Holds the `NotificationCenter` of the web service.
    public var notificationCenter: NotificationCenter {
        .init(app: self)
    }
}
