//
//  File.swift
//  
//
//  Created by Alexander Collins on 25.12.20.
//

import Foundation
import class Vapor.Application
import SwifCron

public class Schedule<K: ApodiniKeys, T: Job>: Configuration {
    private let scheduler = Scheduler.shared
    private let job: T
    private let cronTrigger: String
    private let runs: Int?
    private let keyPath: KeyPath<K, T>
    
    public init(_ job: T, on cronTrigger: String, _ keyPath: KeyPath<K, T>) {
        self.job = job
        self.cronTrigger = cronTrigger
        self.runs = nil
        self.keyPath = keyPath
    }
    
    public init(_ job: T, on cronTrigger: String, runs: Int, _ keyPath: KeyPath<K, T>) {
        self.job = job
        self.cronTrigger = cronTrigger
        self.runs = runs
        self.keyPath = keyPath
    }
    
    public func configure(_ app: Application) {
        do {
            try scheduler.enqueue(job, with: cronTrigger, runs: runs, keyPath, on: app.eventLoopGroup.next())
        } catch JobErrors.requestPropertyWrapper {
            fatalError("Request based property wrappers cannot be used with `Job`s")
        } catch {
            fatalError("Error parsing cron trigger: \(error)")
        }
    }
}
