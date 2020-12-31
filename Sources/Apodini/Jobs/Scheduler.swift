//
//  File.swift
//  
//
//  Created by Alexander Collins on 25.12.20.
//

import Foundation
import SwifCron
import NIO

public class Scheduler {
    internal static var shared = Scheduler()

    private var jobConfigurations: [ObjectIdentifier: JobConfiguration] = [:]
    
    private init() { }
    
    public func enqueue<K: ApodiniKeys, T: Job>(_ job: T,
                                                with cronTrigger: String,
                                                runs: Int? = nil,
                                                _ keyPath: KeyPath<K, T>,
                                                on eventLoop: EventLoop) throws {
        try checkPropertyWrappers(job)
        let jobConfiguration = try generateEnvironmentValue(job, cronTrigger, keyPath)
        
        if let runs = runs {
            schedule(job, with: jobConfiguration, runs, on: eventLoop)
        } else {
            schedule(job, with: jobConfiguration, on: eventLoop)
        }
    }
    
    private func schedule<T: Job>(_ job: T, with config: JobConfiguration, on eventLoop: EventLoop) {
        guard let nextDate = try? config.cron.next() else {
            return
        }
        
        let secondsTo = nextDate.timeIntervalSince(Date()) + 1
        
        config.scheduled = eventLoop.scheduleTask(in: .seconds(Int64(secondsTo))) {
            self.schedule(job, with: config, on: eventLoop)
            job.run()
        }
    }
    
    private func schedule<T: Job>(_ job: T, with config: JobConfiguration, _ runs: Int, on eventLoop: EventLoop) {
        guard runs > 0, let nextDate = try? config.cron.next() else {
            return
        }
        
        let secondsTo = nextDate.timeIntervalSince(Date()) + 1
        
        config.scheduled = eventLoop.scheduleTask(in: .seconds(Int64(secondsTo))) {
            self.schedule(job, with: config, runs - 1, on: eventLoop)
            job.run()
        }
    }
    
    public func dequeue<K: ApodiniKeys, T: Job>(_ keyPath: KeyPath<K, T>) throws {
        guard let config = jobConfigurations[ObjectIdentifier(keyPath)] else {
            throw JobErrors.notFound
        }
        
        config.scheduled?.cancel()
    }
    
    /// Checks if only valid property wrappers are used with `Job`s.
    private func checkPropertyWrappers<T: Job>(_ job: T) throws {
        for property in Mirror(reflecting: job).children
        where property.value is RequestInjectable {
            throw JobErrors.requestPropertyWrapper
        }
    }
    
    private func generateEnvironmentValue<K: ApodiniKeys, T: Job>(_ job: T,
                                                                  _ cronTrigger: String,
                                                                  _ keyPath: KeyPath<K, T>) throws -> JobConfiguration {
        let identifier = ObjectIdentifier(keyPath)
        let jobConfiguration = try JobConfiguration(SwifCron(cronTrigger))
        EnvironmentValues.shared.values[identifier] = job
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
