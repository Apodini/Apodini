//
//  File.swift
//  
//
//  Created by Alexander Collins on 25.12.20.
//

import SwifCron
import Foundation
import class Vapor.Application
import NIO

internal class Scheduler {
    internal static var shared = Scheduler()
    
    private init() { }
    
    internal func schedule<T: Job>(_ job: T, _ cronTrigger: String, on eventLoop: EventLoop) {
        do {
            let cron = try SwifCron(cronTrigger)
            let nextDate = try cron.next(from: Date())
            let secondsTo = nextDate.timeIntervalSince1970 - Date().timeIntervalSince1970 + 1

            _ = eventLoop.scheduleTask(in: .seconds(Int64(secondsTo))) {
                self.schedule(job, cronTrigger, on: eventLoop)
                job.run()
            }
        } catch {
            print("Something went wrong")
        }
    }
    
    internal func schedule<T: Job>(_ job: T, _ cronTrigger: String, runs: Int, on eventLoop: EventLoop) {
        if runs > 0 {
            do {
                let cron = try SwifCron(cronTrigger)
                let nextDate = try cron.next(from: Date())
                let secondsTo = nextDate.timeIntervalSince1970 - Date().timeIntervalSince1970 + 1

                _ = eventLoop.scheduleTask(in: .seconds(Int64(secondsTo))) {
                    self.schedule(job, cronTrigger, runs: runs - 1, on: eventLoop)
                    job.run()
                }
            } catch {
                print("Something went wrong")
            }
        }
    }
}
