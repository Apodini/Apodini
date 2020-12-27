//
//  File.swift
//  
//
//  Created by Alexander Collins on 25.12.20.
//

import Foundation
import class Vapor.Application

public class Schedule<T: Job>: Configuration {
    private let scheduler = Scheduler.shared
    private let job: T
    private let cronTrigger: String
    private let runs: Int?
    
    public init(_ job: T, on cronTrigger: String, file: StaticString = #file, line: UInt = #line) {
        self.job = job
        self.cronTrigger = cronTrigger
        self.runs = nil
        
        check(file, line)
    }
    
    public init(_ job: T, on cronTrigger: String, runs: Int, file: StaticString = #file, line: UInt = #line) {
        self.job = job
        self.cronTrigger = cronTrigger
        self.runs = runs
        
        check(file, line)
    }
    
    public func configure(_ app: Application) {
        if let runs = runs {
            scheduler.schedule(job, cronTrigger, runs: runs, on: app.eventLoopGroup.next())
        } else {
            scheduler.schedule(job, cronTrigger, on: app.eventLoopGroup.next())
        }
    }
    
    /// Checks if only valid property wrappers are used with `Job`s.
    private func check( _ file: StaticString, _ line: UInt) {
        for property in Mirror(reflecting: job).children where property.value is RequestInjectable {
            fatalError("Request based property wrappers cannot be used with `Job`s", file: file, line: line)
        }
    }
    
    private func generateEnvironmentValue() {
        fatalError("Not implemented")
    }
}
