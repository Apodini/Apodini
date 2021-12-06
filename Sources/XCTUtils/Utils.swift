import XCTest

extension XCTestCase {
    /// Whether the test case is running within Xcode.
    /// This will return false when run via the Terminal, e.g. via `swift test`
    public static var isRunningInXcode: Bool {
        ProcessInfo.processInfo.environment["__CFBundleIdentifier"] == "com.apple.dt.Xcode"
    }
    
    /// Skips the current test if the tests are running in Xcode.
    /// This is useful in some cases, since Xcode can sometimes lead to tests behaving differently
    /// as compared to when they're run via the termial, especially when dealing with child processes.
    public func skipIfRunningInXcode() throws {
        if Self.isRunningInXcode {
            throw XCTSkip("Skipping because the test is running in Xcode")
        }
    }
}
