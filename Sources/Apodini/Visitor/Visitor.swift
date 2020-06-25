protocol Visitor {
    mutating func enter<C: Component>(_ component: C)
    mutating func addContext<P: CustomStringConvertible>(label: String?, _ property: P)
    mutating func register<C: Component>(_ component: C)
    mutating func exit<C: Component>(_ component: C)
}

protocol Visitable {
    func visit<V: Visitor>(_ visitor: inout V)
}

//protocol Visitable {
//    func visit(_ visitor: inout Visitor)
//}
//
//struct Visitor {
//    var value: Int
//}
//
//struct A: Visitable {
//    func visit(_ visitor: inout Visitor) {
//        visitor.value += 1
//    }
//}
//
//struct B<T: Visitable>: Visitable {
//    var content: T
//}
//
//var visitor = Visitor()
//var foo = A()
//foo.visit(&visitor)
//print(visitor.value)
