@testable import Apodini
@testable import ApodiniDatabase
@testable import ApodiniREST
import Vapor
import XCTApodini

final class DownloaderTests: FileHandlerTests {
    func testSingleDownloader() throws {
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        try newerXCTCheckHandler(Uploader(UploadConfiguration(.default, subPath: "Misc/"))) {
            MockRequest(expectation: Expectation.response(status: .created, file.filename)) {
                UnnamedParameter(file)
            }
        }
        
        try newerXCTCheckHandler(SingleDownloader(DownloadConfiguration(.default))) {
            MockRequest(expectation: Expectation.response(file)) {
                UnnamedParameter("Testfile.jpeg")
            }
        }
    }
    
    func testMultipleDownloader() throws {
        // Upload first file
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        try newerXCTCheckHandler(Uploader(UploadConfiguration(.default, subPath: "Misc/"))) {
            MockRequest(expectation: Expectation.response(status: .created, file.filename)) {
                UnnamedParameter(file)
            }
        }
        
        // Upload second file
        let file2 = File(data: data, filename: "Testfile123.jpeg")
        
        try newerXCTCheckHandler(Uploader(UploadConfiguration(.default, subPath: "Misc/MoreMisc/"))) {
            MockRequest(expectation: Expectation.response(status: .created, file2.filename)) {
                UnnamedParameter(file2)
            }
        }
        
        let response = try XCTUnwrap(
            try newerXCTCheckHandler(MultipleDownloader(DownloadConfiguration(.default))) {
                MockRequest<[ApodiniDatabase.File]> {
                    UnnamedParameter(".jpeg")
                }
            }
        )
        
        XCTAssert(response.count == 2)
        XCTAssert(response[0] == file || response[0] == file2)
        XCTAssert(response[1] == file || response[1] == file2)
    }
}
