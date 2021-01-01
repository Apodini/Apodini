import SwifCron
import NIO

/// Protocol
public protocol Job {
    /// Method when the `Job`
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
