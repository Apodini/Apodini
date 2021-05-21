//
// Created by Andreas Bauer on 21.05.21.
//

extension Never: ContextKey, OptionalContextKey {
    public static var defaultValue: Never {
        fatalError("The ContextKey default value cannot be accessed for ContextKey of type Never")
    }
}
