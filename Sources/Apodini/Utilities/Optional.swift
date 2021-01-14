//
// Created by Andi on 25.12.20.
//

@_implementationOnly import Runtime

protocol ApodiniOptional {
    associatedtype Member

    // Disabling syntactic_sugar, improves readability and showcases what really happens here.
    // swiftlint:disable:next syntactic_sugar
    var optionalInstance: Optional<Member> { get }
}

// MARK: Apodini Optional
extension Optional: ApodiniOptional {
    // Disabling syntactic_sugar, improves readability and showcases what really happens here.
    // swiftlint:disable:next syntactic_sugar
    var optionalInstance: Optional<Wrapped> { self }
}

/// Adds the shortcut `.null` if you have a double Optional type to create a Wrapped?(nil) value,
/// meaning a `Optional` containing a `Optional.none` aka a empty `Optional`.
extension Optional where Wrapped: ExpressibleByNilLiteral {
    static var null: Self {
        .some(nil)
    }
}

func isOptional<T>(_ type: T.Type = T.self) -> Bool {
    do {
        let typeInfo = try Runtime.typeInfo(of: type)
        return typeInfo.kind == .optional
    } catch {
        // typeInfo(of:) only throws if the `Kind` enum isn't one of the supported cases:
        //  .struct, .class, .existential, .tuple, .enum, .optional.
        // Thus if it throws, we know for sure that it isn't a optional.
        return false
    }
}
