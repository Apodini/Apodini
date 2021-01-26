/// An object that publishes changes of `@Published` properties.
/// `ObservableObject`s are used with the property wrapper `@ObservedObject` inside of `Handler`s or `Job`s to re-evaluate them.
///
/// Example of an `ObservableObject` with two `@Published` properties.
/// ```
/// class Bird: ObservableObject {
///     @Published var name: String
///     @Published var age: Int
///
///     init(name: String, age: Int) {
///         self.name = name
///         self.age = age
///     }
/// }
/// ```
public protocol ObservableObject {}
