//
//  File.swift
//  
//
//  Created by Alexander Collins on 25.12.20.
//

import SwifCron
import NIO

public protocol Job {
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

public enum JobErrors: Error {
    case requestPropertyWrapper
    case notFound
}
