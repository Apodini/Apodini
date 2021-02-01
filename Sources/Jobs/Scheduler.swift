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
    private let app: Application
    internal var jobConfigurations: [ObjectIdentifier: JobConfiguration] = [:]
    internal var observations: [Observation] = []
    
    init(app: Application) {
        self.app = app
    }
    
    /// Schedules a `Job` on the next event loop of `eventLoopGroup`.
    ///
    /// ```
    /// enqueue(Job(), with: "* * * * *", \KeyStore.job)
    /// ```
    ///
    /// - Parameters:
    ///     - job: The background running task conforming to `Job`s.
    ///     - with: Crontab as a String.
    ///     - runs: Number of times a `Job` should run.
    ///     - keyPath: Associates a `Job` for later retrieval.
    ///
    /// - Throws: If the `Job` uses request based property wrappers or the crontab cannot be parsed.
    public func enqueue<K: EnvironmentAccessible, T: Job>(_ job: T,
                                             with cronTrigger: String,
                                             runs: Int? = nil,
                                             _ keyPath: KeyPath<K, T>) throws {
        try enqueue(job, with: cronTrigger, runs: runs, keyPath, on: app.eventLoopGroup.next())
    }
    
    /// Schedules a `Job` on an event loop.
    ///
    /// ```
    /// enqueue(Job(), with: "* * * * *", \KeyStore.job, on: request.eventLoop)
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
    public func enqueue<K: EnvironmentAccessible, T: Job>(_ job: T,
                                             with cronTrigger: String,
                                             runs: Int? = nil,
                                             _ keyPath: KeyPath<K, T>,
                                             on eventLoop: EventLoop) throws {
        // Only valid property wrappers can be used with `Job`s.
        try check(on: job,
                  for: Environment<Application, Connection>.self,
                  throw: JobErrors.requestPropertyWrapper)
        try check(on: job,
                  for: RequestBasedPropertyWrapper.self,
                  throw: JobErrors.requestPropertyWrapper)
        
        // Activates all `Activatable`s.
        var activatedJob = job
        activate(&activatedJob)
        
        // Inject the application instance to all `ApplicationInjectables`.
        inject(app: app, to: &activatedJob)
        
        // Adds the `Job`to `@Environment`.
        app.storage[keyPath] = activatedJob
        
        // Creates the configuration of the `Job`.
        let jobConfiguration = try generateConfiguration(cronTrigger, keyPath, eventLoop)
        
        // Subscribes to all `ObservedObject`s
        // using a closure that takes each `ObservedObject`.
        let observation = subscribe(on: activatedJob,
                                    using: { observedObject in
                                        // Executes the `Job` on its own event loop
                                        jobConfiguration.eventLoop.execute {
                                            observedObject.changed = true
                                            activatedJob.run()
                                            observedObject.changed = false
                                        }
                                    }
        )
        // Only adds the observation if it is present.
        if let observation = observation {
            observations.append(observation)
        }
        
        if let runs = runs {
            schedule(activatedJob, with: jobConfiguration, runs, on: eventLoop)
        } else {
            schedule(activatedJob, with: jobConfiguration, on: eventLoop)
        }
    }
    
    /// Stops the execution of a `Job`.
    ///
    /// - Parameter keyPath: Associatesd key path of a `Job`.
    ///
    /// - Throws: This method throws an exception if the `Job` cannot be found.
    public func dequeue<K: EnvironmentAccessible, T: Job>(_ keyPath: KeyPath<K, T>) throws {
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
            config.scheduled?.cancel()
            return
        }
        
        let secondsTo = nextDate.timeIntervalSince(Date()) + 1
        
        config.scheduled = eventLoop.scheduleTask(in: .seconds(Int64(secondsTo))) {
            self.schedule(job, with: config, runs - 1, on: eventLoop)
            job.run()
        }
    }
    
    /// Generates the configuration of the `Job`.
    func generateConfiguration<K: EnvironmentAccessible, T: Job>(_ cronTrigger: String,
                                                    _ keyPath: KeyPath<K, T>,
                                                    _ eventLoop: EventLoop) throws -> JobConfiguration {
        let identifier = ObjectIdentifier(keyPath)
        let jobConfiguration = try JobConfiguration(SwifCron(cronTrigger), eventLoop)
        jobConfigurations[identifier] = jobConfiguration
        
        return jobConfiguration
    }
}
