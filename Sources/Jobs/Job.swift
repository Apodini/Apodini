@_implementationOnly import SwifCron
import NIO
import Apodini

/// `Job`s allow to create background running tasks
/// and conform `ObservableObject` to trigger the evaluation of other objects.
public protocol Job: ObservableObject {
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
