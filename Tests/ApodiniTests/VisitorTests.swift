import XCTest
@testable import Apodini


final class VisitorTests: XCTestCase {
    struct TestResponseMediator: ResponseMediator {
        let text: String
        
        init(_ response: String) {
            text = response
        }
    }
    
    struct PrintVisitor: Visitor {
        private var intendationLevel: UInt = 0
        
        
        private var intendation: String {
            String(repeating: "  ", count: Int(intendationLevel))
        }
        
        
        mutating func enter<C>(_ component: C) where C : Component {
            let baseType = String(describing: component.self).components(separatedBy: "<").first ?? "UNKNOWN"
            print("\(intendation)\(baseType):")
            intendationLevel += 1
        }
        
        mutating func addContext<P>(label: String?, _ property: P) where P : CustomStringConvertible {
            Swift.print("\(intendation)\(label ?? "_") = \(property)")
        }
        
        mutating func register<C>(_ component: C) where C : Component {
            Swift.print("\(intendation)\(component)")
        }
        
        mutating func exit<C>(_ component: C) where C : Component {
            intendationLevel = max(0, intendationLevel - 1)
        }
    }
    
    
    func api() -> some Component {
        API(version: 1) {
            Group("Test") {
                Text("Hallo")
                    .httpType(.put)
                    .response(TestResponseMediator.self)
            }
            Group("Greetings") {
                Group("Human") {
                    Text("👋")
                        .httpType(.get)
                }
                Group("Plant") {
                    Text("🍀")
                        .httpType(.get)
                }
            }
        }
    }
    
    func testTreeParser() {
        var printVisitor = PrintVisitor()
        let testAPI = api()
        testAPI.visit(&printVisitor)
    }
}
