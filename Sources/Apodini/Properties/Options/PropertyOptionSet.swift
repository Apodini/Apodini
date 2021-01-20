import Foundation


/// A `PropertyOptionSet` collects different type erasued `PropertyOptionKey`s.
struct PropertyOptionSet<Property> {
    private let options: [AnyPropertyOptionKey: Any]

    init() {
        options = [:]
    }
    
    init(_ options: [AnyPropertyOption<Property>]) {
        var combined: [AnyPropertyOptionKey: Any] = [:]
        for option in options {
            if let lhs = combined[option.key] {
                combined[option.key] = option.key.combine(lhs: lhs, rhs: option.value)
            } else {
                combined[option.key] = option.value
            }
        }

        self.options = combined
    }
    
    
    func option<Option>(for key: PropertyOptionKey<Property, Option>) -> Option? {
        guard let option = options[key] as? Option else {
            return nil
        }
        
        return option
    }
    
    var isEmpty: Bool {
        self.options.isEmpty
    }
}

extension PropertyOptionSet: CustomDebugStringConvertible {
    var debugDescription: String {
        "[" + self.options.map { option in "\(option.key)(\(option.value))" }.joined(separator: ", ") + "]"
    }
}
