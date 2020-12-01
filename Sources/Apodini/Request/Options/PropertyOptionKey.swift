import Foundation

public class AnyPropertyOptionKey : NSObject {
    func combine(lhs: Any, rhs: Any) -> Any {
        fatalError("AnyPropertyOptionKey.combine should be overridden!")
    }
}
public class PropertyOptionKey<Property, Option: PropertyOption> : AnyPropertyOptionKey {
    override func combine(lhs: Any, rhs: Any) -> Any {
        // swiftlint:disable next
        return (lhs as! Option) & (rhs as! Option)
    }
}
