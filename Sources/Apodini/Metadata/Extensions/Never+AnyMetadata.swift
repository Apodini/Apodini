//
// Created by Andreas Bauer on 21.05.21.
//

extension Never: AnyMetadata {
    public func accept(_ visitor: SyntaxTreeVisitor) {
        fatalError("Can't accept Component Never") // TODO
    }
}
