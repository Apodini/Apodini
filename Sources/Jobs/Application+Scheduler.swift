import Apodini

extension Application {
    /// Holds the `Scheduler` of the web service.
    public var scheduler: Scheduler {
        if let storedScheduler = self.storage[SchedulerStorageKey.self] {
            return storedScheduler
        }
        let newScheduler = Scheduler(app: self)
        self.storage[SchedulerStorageKey.self] = newScheduler

        return newScheduler
    }

    struct SchedulerStorageKey: StorageKey {
        typealias Value = Scheduler
    }
}
