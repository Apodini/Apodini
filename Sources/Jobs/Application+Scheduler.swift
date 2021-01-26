import Apodini

extension Application {
    /// Holds the `Scheduler` of the web service.
    public var scheduler: Scheduler {
        if let scheduler = self.storage[SchedulerStorageKey.self] {
            return scheduler
        }
        let scheduler = Scheduler(app: self)
        self.storage[SchedulerStorageKey.self] = scheduler

        return scheduler
    }

    struct SchedulerStorageKey: StorageKey {
        typealias Value = Scheduler
    }
}
