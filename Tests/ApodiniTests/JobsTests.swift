//
//  File.swift
//  
//
//  Created by Alexander Collins on 29.12.20.
//

@testable import Apodini
import XCTest


final class JobsTests: ApodiniTests {
    class TestJob: Job {
        func run() {
            print("Hello World")
        }
    }
    
    func testRequestBasedPropertyWrappers() throws {
//        XCTAssertThrowsError(Schedule(TestJob(), on: "*/10 * * * *").configure(app))
    }
}
