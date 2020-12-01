import Foundation

public struct PropertyOptionSet<Property> {
    private let options: [AnyPropertyOptionKey: Any]

    public init() {
        options = [:]
    }

    public init(_ options: [AnyPropertyOption<Property>]) {
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

    public func option<Option>(for key: PropertyOptionKey<Property, Option>) -> Option? {
        guard let option = options[key] else { return nil }
        // swiftlint:disable next
        return (option as! Option)
    }
}
