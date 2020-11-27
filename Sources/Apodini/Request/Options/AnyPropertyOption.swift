import Foundation

public struct AnyPropertyOption<Property> {
    let key: AnyPropertyOptionKey
    let value: Any

    public init<Option>(key: PropertyOptionKey<Property, Option>, value: Option) {
        self.key = key
        self.value = value
    }
}
