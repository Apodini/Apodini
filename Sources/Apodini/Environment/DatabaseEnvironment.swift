import protocol Fluent.Database

/// An environment key that can be used to access the database property of the environment
enum DatabaseEnvironmentKey: EnvironmentKey {
    /// The default value of the database property. It will throw an error if not value has been set.
    static var defaultValue: Database {
        fatalError("Database is accessed, but has never been set")
    }
}

extension EnvironmentValues {
    /// A Property containing the database that was set during the configuration by `DatabaseConfiguration`.
    public var database: Database {
        get { self[DatabaseEnvironmentKey.self] }
        set { self[DatabaseEnvironmentKey.self] = newValue }
    }
}
