import Foundation

public struct TupleComponent<T>: Component, SyntaxTreeVisitable {
    public typealias Content = Never
    
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
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        visitor.enterContent {
            let mirror = Mirror(reflecting: storage)
            for (_, value) in mirror.children {
                visitor.enterComponentContext {
                    do {
                        try visitor.unsafeVisitAny(value)
                    } catch {
                        // Since init is internal & we only create Tuple Components in the Component Builder
                        // We know for a fact that unsafeVisit won't fail.
                        #if DEBUG
                        fatalError("Attempted to visit value that was not a component. It was instantiated from \(file):\(function): \(error)")
                        #else
                        fatalError("\(error)")
                        #endif
                    }
                }
            }
        }
    }
}
