//
// Created by Andreas Bauer on 06.07.21.
//

/// Describes a type erased version of an ``Information`` instance.
public protocol AnyInformation {
    /// Returns the type erased value of a ``Information``.
    var value: Any { get }

    /// Accepts a ``InformationSet`` instance which is used to collect the given ``AnyInformation``.
    /// - Parameter visitor: The ``InformationSet`` which should collect this instance.
    func collect(_ set: inout InformationSet)
}

internal extension AnyInformation {
    /// Returns the type version of the ``AnyInformation`` instance.
    /// - Parameter type: The ``AnyInformation`` type
    /// - Returns: Returns the casted ``AnyInformation`` instance.
    func typed<T: AnyInformation>(to type: T.Type = T.self) -> T {
        guard let typed = self as? T else {
            fatalError("Tried typing AnyInformation with type \(self) to \(T.self)")
        }

        return typed
    }
}
