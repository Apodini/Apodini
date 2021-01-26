@testable import Apodini
import XCTest

final class WebserviceTests: XCTestCase {

    func testMain() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Text("42")
            }
        }

        try TestWebService.main(waitForCompletion: false)
    }
}
