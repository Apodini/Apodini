import Foundation
import Apodini
@_implementationOnly import SwifCron

/// `Configuration` to start `Job`s at server startup.
public class Schedule<K: KeyChain, T: Job>: Configuration {
    private let job: T
    private let cronTrigger: String
    private let runs: Int?
    private let keyPath: KeyPath<K, T>
    
    /// Initializes the `Schedule` configuration.
    ///
    /// - Parameters:
    ///     - job: The background running task conforming to `Job`s.
    ///     - on: Crontab as a String.
    ///     - keyPath: Associates a `Job` for later retrieval.
    public init(_ job: T, on cronTrigger: String, _ keyPath: KeyPath<K, T>) {
        self.job = job
        self.cronTrigger = cronTrigger
        self.runs = nil
        self.keyPath = keyPath
        
        createEnvironmentValue()
    }
    
    /// Initializes the `Schedule` configuration.
    ///
    /// - Parameters:
    ///     - job: The background running task conforming to `Job`s.
    ///     - on: Crontab as a String.
    ///     - runs: Number of times a `Job` should run.
    ///     - keyPath: Associates a `Job` for later retrieval.
    public init(_ job: T, on cronTrigger: String, runs: Int, _ keyPath: KeyPath<K, T>) {
        self.job = job
        self.cronTrigger = cronTrigger
        self.runs = runs
        self.keyPath = keyPath
        
        createEnvironmentValue()
    }
    
    /// Enqueues the configured `Job` at server startup.
    public func configure(_ app: Application) {
        do {
            try app.scheduler.enqueue(job, with: cronTrigger, runs: runs, keyPath, on: app.eventLoopGroup.next())
        } catch JobErrors.requestPropertyWrapper {
            fatalError("Request based property wrappers cannot be used with `Job`s")
        } catch {
            fatalError("Error parsing cron trigger: \(error)")
        }
    }
    
    private func createEnvironmentValue() {
        EnvironmentValue(keyPath, job)
    }
}
