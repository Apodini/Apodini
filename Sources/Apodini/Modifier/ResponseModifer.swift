protocol ResponseMediator {
    associatedtype Response
    
    init(_ response: Response)
}

struct ResponseModifier<M: ResponseMediator>: ComponentModifier {
    init(_ type: M.Type) {}
    
    func modify(content: Self.ModifiedComponent) -> some Component {
        content
    }
}

extension Component {
    func response<M: ResponseMediator>(_ modifier: M.Type) -> some Component {
        ModifiedComponent(modifiedComponent: self,
                          modifier: ResponseModifier(M.self))
    }
}
