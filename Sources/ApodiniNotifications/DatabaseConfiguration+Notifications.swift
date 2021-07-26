//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import ApodiniDatabase

extension DatabaseConfiguration {
    /// Adds a database migration which is used by the `NotificationCenter`.
    /// 
    /// This will add the models: `DeviceDatabaseModel`, `DeviceTopic`, and `Topic` to the database.
    public func addNotifications() -> Self {
        self.addMigrations(DeviceMigration())
    }
}
