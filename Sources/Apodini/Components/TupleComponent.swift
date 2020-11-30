import Foundation

public struct TupleComponent<T>: Component {
    private let storage: T
    #if DEBUG
    let file: StaticString
    let function: StaticString
    #endif

    #if DEBUG
    init(_ storage: T, file: StaticString = #file, function: StaticString = #function) {
        self.storage = storage
        self.file = file
        self.function = function
    }
    #else
    init(_ storage: T) {
        self.storage = storage
    }
    #endif
}

extension TupleComponent: Visitable {
    func visit(_ visitor: SynaxTreeVisitor) {
        let mirror = Mirror(reflecting: storage)
        for (_, value) in mirror.children {
            visitor.enterCollectionItem()
            do {
                try visitor.unsafeVisitAny(value)
            } catch {
                // Since init is internal & we only create Tuple Components in the Component Builder
                // We know for a fact that unsafeVisit won't fail.
                #if DEBUG
                fatalError("Attemted to visit value that was not a component. It was instantiated from \(file):\(function): \(error)")
                #else
                fatalError(error)
                #endif
            }
            visitor.exitCollectionItem()
        }
    }
}
