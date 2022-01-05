import Apodini
import ApodiniExtension
import ApodiniHTTP

@main
struct ErrorForwardingTestWebService: WebService {
    var content: some Component {
        Greeter()
    }

    var configuration: Configuration {
        ErrorForwarderConfiguration()
        HTTP()
    }
}

// MARK: -

struct Greeter: Handler {
    @Throws(.serverError, reason: "test error")
    var testError

    @Parameter var country: String?

    func handle() throws -> String {
        if (country?.count ?? 0) < 3 {
            throw testError
        }
        return "Hello, \(country ?? "World")!"
    }
}

// MARK: -

final class ErrorForwarderConfiguration: Configuration {
    func configure(_ app: Application) {
        let exporter = ErrorForwarderExporter()

        app.registerExporter(exporter: exporter)
    }
}

struct ErrorForwarderExporter: InterfaceExporter {
    func export<H>(_ endpoint: Endpoint<H>) -> () where H : Handler {
        endpoint[ErrorForwarder.self] = try! ErrorForwarder(from: { error in
            print("forwarded error", error)
        })
    }

    func export<H>(blob endpoint: Endpoint<H>) -> () where H : Handler, H.Response.Content == Blob {
        fatalError()
    }
}
