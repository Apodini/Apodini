//
// Created by Andreas Bauer on 21.05.21.
//

struct AnyHandlerMetadataArrayWrapper: AnyMetadataGroup, AnyHandlerMetadata {
    let array: [AnyHandlerMetadata]

    init(_ array: [AnyHandlerMetadata]) {
        self.array = array
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.accept(visitor)
        }
    }
}

struct AnyComponentOnlyMetadataArrayWrapper: AnyMetadataGroup, AnyComponentOnlyMetadata {
    let array: [AnyComponentOnlyMetadata]

    init(_ array: [AnyComponentOnlyMetadata]) {
        self.array = array
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.accept(visitor)
        }
    }
}

struct AnyWebServiceMetadataArrayWrapper: AnyMetadataGroup, AnyWebServiceMetadata {
    let array: [AnyWebServiceMetadata]

    init(_ array: [AnyWebServiceMetadata]) {
        self.array = array
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.accept(visitor)
        }
    }
}

struct AnyComponentMetadataArrayWrapper: AnyMetadataGroup, AnyComponentMetadata {
    let array: [AnyComponentMetadata]

    init(_ array: [AnyComponentMetadata]) {
        self.array = array
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.accept(visitor)
        }
    }
}

struct AnyContentMetadataArrayWrapper: AnyMetadataGroup, AnyContentMetadata {
    let array: [AnyContentMetadata]

    init(_ array: [AnyContentMetadata]) {
        self.array = array
    }

    func accept(_ visitor: SyntaxTreeVisitor) {
        for element in array {
            element.accept(visitor)
        }
    }
}
