@_implementationOnly import Runtime

public func LKConstructEnum(_ enumType: Any.Type, caseIndex: Int, payload: Any?) throws -> Any {
    let TI = try typeInfo(of: enumType)
    precondition(TI.kind == .enum)
    precondition(TI.genericTypes.isEmpty)
    print(payload)
    print(TI)
    
    let cases = TI.cases
    
    if TI.numberOfEnumCases == 0 {
        precondition(payload == nil)
        fatalError("Empty enums can't be constructed, right?")
    }
    
    fatalError()
}
