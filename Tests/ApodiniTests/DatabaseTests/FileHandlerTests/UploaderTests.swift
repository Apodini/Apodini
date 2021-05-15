import Foundation
@testable import Apodini
@testable import ApodiniDatabase
import XCTApodini

final class UploaderTests: FileHandlerTests {
    func testUploader() throws {
        let uploader = Uploader(UploadConfiguration(.default, subPath: "Misc/"))
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        try newerXCTCheckHandler(uploader) {
            MockRequest(expectation: .response(status: .created, file.filename)) {
                UnnamedParameter(file)
            }
        }
    }
    
    func testUploadConfig() throws {
        let directory = app.directory
        let config = UploadConfiguration(.public, subPath: "Misc/MoreMisc/")
        let path = config.validatedPath(directory, fileName: "TestFile.jpeg")
        XCTAssert(directory.publicDirectory.appending("Misc/MoreMisc/TestFile.jpeg") == path)
    }
}
