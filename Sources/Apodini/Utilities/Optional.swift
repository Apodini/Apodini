//
// Created by Andi on 25.12.20.
//

@_implementationOnly import Runtime
@_implementationOnly import AssociatedTypeRequirementsVisitor

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


// MARK: - Optional
func isNil(_ value: Any) -> Bool {
    let visitor = ApodiniOptionalIsNilVisitor()
    return visitor(value) ?? false
}

private protocol ApodiniOptionalVisitor: AssociatedTypeRequirementsVisitor {
    associatedtype Visitor = ApodiniOptionalVisitor
    associatedtype Input = ApodiniOptional
    associatedtype Output

    func callAsFunction<T: ApodiniOptional>(_ value: T) -> Output
}

private extension ApodiniOptionalVisitor {
    @inline(never)
    @_optimize(none)
    func _test() {
        let test: String? = "asdf"
        _ = self(test)
    }
}

private struct ApodiniOptionalIsNilVisitor: ApodiniOptionalVisitor {
    func callAsFunction<T: ApodiniOptional>(_ value: T) -> Bool {
        value.optionalInstance == nil
    }
}
