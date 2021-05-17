//
//  Created by Andreas Bauer on 17.05.21.
//

public struct TupleMetadata<T>: AnyMetadata {
    private let storage: T
    
    init(_ storage: T) {
        self.storage = storage
    }
    
    public func accept(_ visitor: SyntaxTreeVisitor) {
        let mirror = Mirror(reflecting: storage)
        for (_, value) in mirror.children {
            do {
                try visitor.unsafeVisitMetadata(value)
            } catch {
                // We know, that a TupleMetadata is only initialized by us in the Metadata result builders.
                // If it fails, someone has fucked up the code generation of those :/
                fatalError("\(error)")
            }
        }
    }
}
