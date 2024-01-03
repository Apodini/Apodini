//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import NIO
import Apodini
@_implementationOnly import SwifCron

/// `Job`s allow to create background running tasks
/// and conform `ObservableObject` to trigger the evaluation of other objects.
public protocol Job: ObservableObject {
    /// Method called when the `Job` is executed.
    func run()
}

internal class JobConfiguration {
    let cron: SwifCron
    let eventLoop: any EventLoop
    var scheduled: Scheduled<()>?
    
    init(_ cron: SwifCron, _ eventLoop: any EventLoop, _ scheduled: Scheduled<()>? = nil) {
        self.cron = cron
        self.eventLoop = eventLoop
        self.scheduled = scheduled
    }
}

internal enum JobErrors: Error {
    case requestPropertyWrapper
    case notFound
}

protocol RequestBasedPropertyWrapper { }

extension Parameter: RequestBasedPropertyWrapper { }
