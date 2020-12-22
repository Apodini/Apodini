import Vapor
import Fluent

@propertyWrapper
struct Param: RequestInjectable {
    
    private var context: DatabaseInjectionContext

    var _value: String?
    
    var wrappedValue: String? {
        return _value
    }
    
    init(context: DatabaseInjectionContext) {
        self.context = context
    }
    
    mutating func inject(using request: Request, with decoder: RequestInjectableDecoder?) throws {
        if let decoder = decoder {
            _value = try decoder.decode(String.self, with: context, from: request)
        }
    }
}
