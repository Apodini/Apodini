import NIO
import NIOFoundationCompat
import Foundation


@propertyWrapper
class Body<Element: Codable>: RequestInjectable {
    private var element: Element?
    
    var wrappedValue: Element {
        guard let element = element else {
            fatalError("You can only access the body while you handle a request")
        }
        
        return element
    }
    
    init() { }
    
    func inject(using request: Request) throws {
        guard let data = request.body.getData(at: request.body.readerIndex, length: request.body.readableBytes) else {
            throw HTTPError.internalServerError(reason: "Could not read the HTTP request's body")
        }
        
        element = try JSONDecoder().decode(Element.self, from: data)
    }
    
    func disconnect() {
        self.element = nil
    }
}
