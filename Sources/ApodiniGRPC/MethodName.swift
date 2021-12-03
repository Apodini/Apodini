import Apodini


// MARK: ServiceName

struct GRPCServiceNameContextKey: OptionalContextKey {
    typealias Value = String
}


//public struct GRPCServiceModifier<H: Handler>: HandlerModifier {
//    public let component: H
//    let serviceName: String
//
//    init(_ component: H, serviceName: String) {
//        self.component = component
//        self.serviceName = serviceName
//    }
//
//    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
//        visitor.addContext(GRPCServiceNameContextKey.self, value: serviceName, scope: .current)
//    }
//}
//
//
//extension Handler {
//    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
//    public func gRPCServiceName(_ serviceName: String) -> GRPCServiceModifier<Self> {
//        .init(self, serviceName: serviceName)
//    }
//}

public struct GRPCServiceModifier<C: Component>: Modifier {
    public let component: C
    let serviceName: String
    
    init(_ component: C, serviceName: String) {
        self.component = component
        self.serviceName = serviceName
    }
    
    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCServiceNameContextKey.self, value: serviceName, scope: .environment)
    }
}

extension GRPCServiceModifier: HandlerModifier & Handler & AnyHandlerMetadata & AnyHandlerMetadataBlock & HandlerMetadataNamespace where Self.ModifiedComponent: Handler {
    public typealias Response = C.Response
}


extension Component {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func gRPCServiceName(_ serviceName: String) -> GRPCServiceModifier<Self> {
        .init(self, serviceName: serviceName)
    }
}


// MARK: MethodName

struct GRPCMethodNameContextKey: OptionalContextKey {
    typealias Value = String
}


public struct GRPCMethodModifier<H: Handler>: HandlerModifier {
    public let component: H
    let methodName: String
    
    init(_ component: H, methodName: String) {
        self.component = component
        self.methodName = methodName
    }
    
    public func parseModifier(_ visitor: SyntaxTreeVisitor) {
        visitor.addContext(GRPCMethodNameContextKey.self, value: methodName, scope: .current)
    }
}


extension Handler {
    /// Explicitly sets the name of the gRPC service that is exposed for this `Handler`
    public func gRPCMethodName(_ methodName: String) -> GRPCMethodModifier<Self> {
        .init(self, methodName: methodName)
    }
}




// MARK: TEST


//struct GRPCServiceNameContextKey: OptionalContextKey {
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

