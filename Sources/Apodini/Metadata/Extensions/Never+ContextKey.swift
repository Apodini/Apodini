//
// Created by Andreas Bauer on 21.05.21.
//

extension Never: ContextKey, OptionalContextKey {
    public typealias Value = Never
    public static var defaultValue: Value {
        fatalError("The ContextKey default value cannot be accessed for ContextKey of type Never")
    }
}
