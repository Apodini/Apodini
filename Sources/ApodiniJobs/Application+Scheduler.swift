//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

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
