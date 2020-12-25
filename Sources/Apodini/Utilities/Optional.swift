//
// Created by Andi on 25.12.20.
//

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
