import Foundation
import XCTest
import NIO
@testable import Apodini
@testable import ApodiniDatabase

final class UploaderTests: ApodiniTests {
    
    func testUploader() throws {
        let uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/"))
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        let request = MockRequest.createRequest(on: uploader, running: app.eventLoopGroup.next(), queuedParameters: file)
        let response = try request.enterRequestContext(with: uploader, executing: { component in
            try! component.handle()
        })
        .wait()
        XCTAssert(response == file.filename)
       
    }
    
    func testUploadConfig() throws {
        let directory = Environment(\.directory).wrappedValue
        let config = UploadConfiguration(.public, subPath: "Misc/MoreMisc/")
        let path = config.validatedPath(directory, fileName: "TestFile.jpeg")
        XCTAssert(directory.publicDirectory.appending("Misc/MoreMisc/TestFile.jpeg") == path)
    }
}
