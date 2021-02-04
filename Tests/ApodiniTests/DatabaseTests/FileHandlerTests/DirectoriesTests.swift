import Foundation
import XCTest
@testable import Apodini
@testable import ApodiniDatabase

final class DirectoriesTests: FileHandlerTests {
    func testDirectories() {
        var environment = Environment(\.directory)
        environment.inject(app: app)
        environment.activate()
        let directory = environment.wrappedValue
        
        let publicDir: Directories = .public
        XCTAssert(publicDir.path(for: directory) == self.app.directory.publicDirectory)
        
        let resourceDir: Directories = .resource
        XCTAssert(resourceDir.path(for: directory) == self.app.directory.resourcesDirectory)
        
        let workingDir: Directories = .working
        XCTAssert(workingDir.path(for: directory) == self.app.directory.workingDirectory)
        
        let defaultDir: Directories = .default
        XCTAssert(defaultDir.path(for: directory) == self.app.directory.publicDirectory)
    }
    
    func testApplicationDirectory() {
        let cwd = getcwd(nil, Int(PATH_MAX))
        defer {
            free(cwd)
        }

        let createdDirectory: String

        if let cwd = cwd, let string = String(validatingUTF8: cwd) {
            createdDirectory = string
        } else {
            createdDirectory = "./"
        }
        let directory = Directory.detect()
        XCTAssert(directory.publicDirectory == createdDirectory.appending("/Public/"), createdDirectory)
        XCTAssert(directory.resourcesDirectory == createdDirectory.appending("/Resources/"), createdDirectory)
        XCTAssert(directory.resourcesDirectory == createdDirectory.appending("/Resources/"), createdDirectory)
        XCTAssert(directory.workingDirectory == createdDirectory.appending("/"), createdDirectory)
    }
}
