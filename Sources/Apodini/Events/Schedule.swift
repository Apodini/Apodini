//
//  Schedule.swift
//  
//
//  Created by Alexander Collins on 14.11.20.
//

import Foundation
import Vapor
import VaporCron

public protocol Job {
    var expression: String { get }

    func task()
}

extension Job {
    func scheduleJob(on request: Vapor.Request) {
        do {
            try request.cron.schedule(expression) { self.task() }
        } catch {
            print("Something went wrong \(error)")
        }
    }
}

typealias LazyJob = Job?

public struct ScheduleContext<C: Component>: Modifier {
    let job: LazyJob
    let component: C
    
    init(_ job: LazyJob, _ component: C) {
        self.job = job
        self.component = component
    }
    
    func executeJob(on request: Vapor.Request) {
        do {
            if let job = job {
                try request.cron.schedule(job.expression) { job.task() }
            }
        } catch {
            print("Something went wrong \(error)")
        }
    }
}

struct ScheduleContextKey: ContextKey {
    static var defaultValue: LazyJob = nil

    static func reduce(value: inout LazyJob, nextValue: () -> LazyJob) {
        value = nextValue()
    }
}

extension ScheduleContext: Visitable {
    func visit(_ visitor: SynaxTreeVisitor) {
        visitor.addContext(ScheduleContextKey.self, value: job, scope: .environment)
         component.visit(visitor)
    }
}

extension Component {
    public func schedule(_ job: Job) -> ScheduleContext<Self> {
        ScheduleContext(job, self)
    }
}
