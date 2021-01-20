import Foundation
import NIO
import Apodini
@_implementationOnly import SwifCron

/// A convenient interface to schedule background running tasks on an event loop using `Job`s and crontab syntax.
///
/// `Job`s can either be scheduled at server startup using the `Schedule` configuration or from an `Handler` by using the `@Environment` property wrapper.
/// `Job`s can use all property wrappers that are not request based.
///
/// ```
/// struct Greeter: Handler {
///     @Environment(\.scheduler) var scheduler: Scheduler
/// }
/// ```
public class Scheduler {
    internal static var shared = Scheduler()
    
    internal var jobConfigurations: [ObjectIdentifier: JobConfiguration] = [:]
    
    private init() {
        // Empty intializer to create a Singleton.
    }
    
    /// Schedules a `Job` on an event loop.
    ///
    /// ```
    /// enqueue(Job(), with: "* * * * *", \KeyStore.job, on: request.eventLoop
    /// ```
    ///
    /// - Parameters:
    ///     - job: The background running task conforming to `Job`s.
    ///     - with: Crontab as a String.
    ///     - runs: Number of times a `Job` should run.
    ///     - keyPath: Associates a `Job` for later retrieval.
    ///     - on: Specifies the event loop the `Job` is executed on.
    ///
    /// - Throws: If the `Job` uses request based property wrappers or the crontab cannot be parsed.
    public func enqueue<K: KeyChain, T: Job>(_ job: T,
                                             with cronTrigger: String,
                                             runs: Int? = nil,
                                             _ keyPath: KeyPath<K, T>,
                                             on eventLoop: EventLoop) throws {
        try checkPropertyWrappers(job)
        EnvironmentValue(keyPath, job)
        let jobConfiguration = try generateConfiguration(cronTrigger, keyPath)
        
        if let runs = runs {
            schedule(job, with: jobConfiguration, runs, on: eventLoop)
        } else {
            schedule(job, with: jobConfiguration, on: eventLoop)
        }
    }
    
    /// Stops the execution of a `Job`.
    ///
    /// - Parameter keyPath: Associatesd key path of a `Job`.
    ///
    /// - Throws: This method throws an exception if the `Job` cannot be found.
    public func dequeue<K: KeyChain, T: Job>(_ keyPath: KeyPath<K, T>) throws {
        guard let config = jobConfigurations[ObjectIdentifier(keyPath)] else {
            throw JobErrors.notFound
        }
        
        config.scheduled?.cancel()
    }
}

private extension Scheduler {
    func schedule<T: Job>(_ job: T, with config: JobConfiguration, on eventLoop: EventLoop) {
        guard let nextDate = try? config.cron.next() else {
            return
        }
        
        let secondsTo = nextDate.timeIntervalSince(Date()) + 1
        
        config.scheduled = eventLoop.scheduleTask(in: .seconds(Int64(secondsTo))) {
            self.schedule(job, with: config, on: eventLoop)
            job.run()
        }
    }
    
    func schedule<T: Job>(_ job: T, with config: JobConfiguration, _ runs: Int, on eventLoop: EventLoop) {
        guard runs > 0, let nextDate = try? config.cron.next() else {
            return
        }
        
        let secondsTo = nextDate.timeIntervalSince(Date()) + 1
        
        config.scheduled = eventLoop.scheduleTask(in: .seconds(Int64(secondsTo))) {
            self.schedule(job, with: config, runs - 1, on: eventLoop)
            job.run()
        }
    }
    
    /// Checks if only valid property wrappers are used with `Job`s.
    func checkPropertyWrappers<T: Job>(_ job: T) throws {
        for property in Mirror(reflecting: job).children {
            switch property.value {
            case is Environment<EnvironmentValues, Connection>:
                throw JobErrors.requestPropertyWrapper
            case let observedObject as AnyObservedObject:
                subscribe(job: job, to: observedObject)
            default:
                continue
            }
        }
    }
    
    func subscribe(job: Job, to observedObject: AnyObservedObject) {
        observedObject.valueDidChange = {
            observedObject.setChanged(to: true)
            job.run()
            observedObject.setChanged(to: false)
        }
    }
    
    /// Generates the configuration of the `Job`.
    func generateConfiguration<K: KeyChain, T: Job>(_ cronTrigger: String, _ keyPath: KeyPath<K, T>) throws -> JobConfiguration {
        let identifier = ObjectIdentifier(keyPath)
        let jobConfiguration = try JobConfiguration(SwifCron(cronTrigger))
        jobConfigurations[identifier] = jobConfiguration
        
        return jobConfiguration
    }
}

enum SchedulerEnvironmentKey: EnvironmentKey {
    static var defaultValue = Scheduler.shared
}

extension EnvironmentValues {
    /// The environment value to use the `SchedulerEnvironmentKey` in a `Component`.
    public var scheduler: Scheduler {
        self[SchedulerEnvironmentKey.self]
    }
}
