import XCTest
import NIO
import Apodini
import Jobs

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

func environmentJob<K: KeyChain, T: Job>(_ keyPath: KeyPath<K, T>, app: Application) -> T {
    var environment = Environment(keyPath)
    environment.inject(app: app)
    environment.activate()
    return environment.wrappedValue
}
