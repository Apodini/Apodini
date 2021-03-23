import ApodiniDatabase

extension DatabaseConfiguration {
    /// Adds a database migration which is used by the `NotificationCenter`.
    /// 
    /// This will add the models: `DeviceDatabaseModel`, `DeviceTopic`, and `Topic` to the database.
    public func addNotifications() -> Self {
        self.addMigrations(DeviceMigration())
    }
}
