
import Foundation



extension Sequence {
    func mapIntoDict<Key: Hashable, Value>(_ transform: (Element) throws -> (Key, Value)) rethrows -> [Key: Value] {
        var retval: [Key: Value] = [:]
        for element in self {
            let (key, value) = try transform(element)
            retval[key] = value
        }
        return retval
    }
}


//func == (lhs: Any.Type, rhs: Any.Type)
