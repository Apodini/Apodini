//
// Created by Andreas Bauer on 25.12.20.
//

import ApodiniUtils

//
//protocol ApodiniOptional {
//    associatedtype Wrapped
//    // Disabling syntactic_sugar, improves readability and showcases what really happens here.
//    // swiftlint:disable:next syntactic_sugar
//    var optionalInstance: Optional<Wrapped> { get }
//}
//
//
//// MARK: Apodini Optional
//extension Optional: ApodiniOptional {
//    // Disabling syntactic_sugar, improves readability and showcases what really happens here.
//    // swiftlint:disable:next syntactic_sugar
//    var optionalInstance: Optional<Wrapped> { self }
//}
//
//
///// Adds the shortcut `.null` if you have a double Optional type to create a Wrapped?(nil) value,
///// meaning a `Optional` containing a `Optional.none` aka a empty `Optional`.
//extension Optional where Wrapped: ExpressibleByNilLiteral {
//    static var null: Self {
//        .some(nil)
//    }
//}
//
//
//// MARK: - Optional
//func isNil(_ value: Any) -> Bool {
//    switch value {
//    case Optional<Any>.none:
//        return true
//    default:
//        return false
//    }
//}
//
