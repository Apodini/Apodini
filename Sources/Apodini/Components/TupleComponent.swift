// Question: How do we access the Components in the TupleComponent?
struct TupleComponent<T>: Component {
    typealias Content = Never
    
    private let tuple: T

    init(_ tuple: T) {
        self.tuple = tuple
    }
}
