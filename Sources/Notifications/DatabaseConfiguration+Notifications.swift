import Apodini

extension DatabaseConfiguration {
    public func addNotifications() -> Self {
        _ = self.addMigrations(DeviceMigration())
        return self
    }
}
