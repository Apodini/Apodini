import SwifCron
import NIO

/// `Job`s allow to create background running tasks.
public protocol Job {
    /// Method called when the `Job` is executed.
    func run()
}

internal class JobConfiguration {
    let cron: SwifCron
    var scheduled: Scheduled<()>?
    
    init(_ cron: SwifCron, _ scheduled: Scheduled<()>? = nil) {
        self.cron = cron
        self.scheduled = scheduled
    }
}

internal enum JobErrors: Error {
    case requestPropertyWrapper
    case notFound
}
