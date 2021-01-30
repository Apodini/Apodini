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
    let eventLoop: EventLoop
    var scheduled: Scheduled<()>?
    
    init(_ cron: SwifCron, _ eventLoop: EventLoop, _ scheduled: Scheduled<()>? = nil) {
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
