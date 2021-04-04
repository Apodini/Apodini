@testable import Apodini
@testable import ApodiniDatabase
@testable import ApodiniREST
import Vapor
import XCTApodini

final class DownloaderTests: FileHandlerTests {
    func testSingleDownloader() throws {
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        try XCTCheckHandler(
            Uploader(UploadConfiguration(.default, subPath: "Misc/")),
            application: self.app,
            request: MockExporterRequest(on: self.app.eventLoopGroup.next(), file),
            status: .created,
            content: file.filename
        )
        
        try XCTCheckHandler(
            SingleDownloader(DownloadConfiguration(.default)),
            application: self.app,
            request: MockExporterRequest(on: self.app.eventLoopGroup.next(), "Testfile.jpeg"),
            content: file
        )
    }
    
    func testMultipleDownloader() throws {
        // Upload first file
        let data = try XCTUnwrap(Data(base64Encoded: FileUtilities.getBase64EncodedTestString()))
        let file = File(data: data, filename: "Testfile.jpeg")
        
        try XCTCheckHandler(
            Uploader(UploadConfiguration(.default, subPath: "Misc/")),
            application: self.app,
            request: MockExporterRequest(on: self.app.eventLoopGroup.next(), file),
            status: .created,
            content: file.filename
        )
        
        // Upload second file
        let file2 = File(data: data, filename: "Testfile123.jpeg")
        
        try XCTCheckHandler(
            Uploader(UploadConfiguration(.default, subPath: "Misc/MoreMisc/")),
            application: self.app,
            request: MockExporterRequest(on: self.app.eventLoopGroup.next(), file2),
            status: .created,
            content: file2.filename
        )
        
        // Test the MultipleDownloader
        let response: [ApodiniDatabase.File] = try XCTUnwrap(
            try XCTCheckHandler(
                MultipleDownloader(DownloadConfiguration(.default)),
                application: self.app,
                request: MockExporterRequest(on: self.app.eventLoopGroup.next(), ".jpeg"),
                responseType: [ApodiniDatabase.File].self
            )
        )
        
        XCTAssert(response.count == 2)
        XCTAssert(response[0] == file || response[0] == file2)
        XCTAssert(response[1] == file || response[1] == file2)
    }
}
