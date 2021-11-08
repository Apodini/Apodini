import Apodini


// MARK: ServiceName

struct GRPCv2ServiceNameContextKey: OptionalContextKey {
    typealias Value = String
}


public struct GRPCv2ServiceModifier<H: Handler>: HandlerModifier {
    public let component: H
    let serviceName: String
    
    init(_ component: H, serviceName: String) {
        self.component = component
        self.serviceName = serviceName
    }
    
    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCv2ServiceNameContextKey.self, value: serviceName, scope: .current)
    }
}


extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func gRPCv2ServiceName(_ serviceName: String) -> GRPCv2ServiceModifier<Self> { // TODO drop the v2
        .init(self, serviceName: serviceName)
    }
}


// MARK: MethodName

struct GRPCv2MethodNameContextKey: OptionalContextKey {
    typealias Value = String
}


public struct GRPCv2MethodModifier<H: Handler>: HandlerModifier {
    public let component: H
    let methodName: String
    
    init(_ component: H, methodName: String) {
        self.component = component
        self.methodName = methodName
    }
    
    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCv2MethodNameContextKey.self, value: methodName, scope: .current)
    }
}


extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func gRPCv2MethodName(_ methodName: String) -> GRPCv2MethodModifier<Self> { // TODO drop the v2
        .init(self, methodName: methodName)
    }
}





// MARK: TEST


//struct GRPCv2ServiceNameContextKey: OptionalContextKey {
//    typealias Value = String
//}


public struct Test_1<H: Handler>: HandlerModifier {
    public let component: H
    
    init(_ component: H) {
        self.component = component
    }
    
    public func parseModifier(_ visitor: SyntaxTreeVisitor) {}
}

extension Handler {
    public func test_1() -> Test_1<Self> {
        .init(self)
    }
}



public struct Test_2<H: Handler>: HandlerModifier {
    public let component: H
    
    init(_ component: H) {
        self.component = component
    }
    
    public func parseModifier(_ visitor: SyntaxTreeVisitor) {}
}

extension Handler {
    public func test_2() -> Test_2<Self> {
        .init(self)
    }
}

