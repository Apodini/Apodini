import Foundation
import XCTest
import NIO
@testable import Apodini

class FileHandlerTests: ApodiniTests {
    override func setUpWithError() throws {
        try super.setUpWithError()
        let directory = Environment(\.directory).wrappedValue
        if !FileManager.default.fileExists(atPath: directory.publicDirectory) {
            try FileManager.default.createDirectory(atPath: directory.publicDirectory, withIntermediateDirectories: false, attributes: nil)
        }
    }
    
    // swiftlint:disable overridden_super_call
    override func tearDownWithError() throws {
        // skip super call because calling super after each test func results in an error
        let directory = Environment(\.directory).wrappedValue
        print(directory.publicDirectory)
        if FileManager.default.fileExists(atPath: directory.publicDirectory) {
            try FileManager.default.removeItem(atPath: directory.publicDirectory)
        }
    }
}
