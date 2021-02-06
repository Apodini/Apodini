import Apodini
import ApodiniJobs
import XCTest


// Helper method to test if a Job was correctly executed
func XCTAssertScheduling<T>(_ scheduled: Scheduled<T>) {
    var result = false
    var error: Error?

    // Checks if Job was triggered
    scheduled.futureResult.whenSuccess { _  in result = true }
    // Checks if no error was thrown
    scheduled.futureResult.whenFailure { error = $0 }
    
    XCTAssertTrue(result)
    XCTAssertNil(error)
}
