@testable import Apodini
import XCTest

final class WebserviceTests: XCTestCase {
    func testMain() throws {
        struct TestWebService: WebService {
            var content: some Component {
                Text("42")
            }

            var configuration: Configuration {
                HTTPConfiguration()
                    .address(.hostname("0.0.0.0", port: 8080))
            }
        }

        let app = try TestWebService.start(waitForCompletion: false)
        app.shutdown()
    }
}
