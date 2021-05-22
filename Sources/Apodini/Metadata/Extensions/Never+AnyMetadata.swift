//
// Created by Andreas Bauer on 21.05.21.
//

extension Never: AnyMetadata {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        // as the Never also conforms to Component, we need to manually specify the implementation
        fatalError("Never cannot be accepted by the SyntaxTreeVisitor!")
    }
}
