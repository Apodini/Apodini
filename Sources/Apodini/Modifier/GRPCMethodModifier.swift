//
 //  GRPCMethodModifier.swift
 //
 //
 //  Created by Moritz Schüll on 04.12.20.
 //

 struct GRPCMethodNameContextKey: ContextKey {
     static var defaultValue = ""

     static func reduce(value: inout String, nextValue: () -> String) {
         value = nextValue()
     }
 }

 public struct GRPCMethodModifier<ModifiedComponent: Component>: Modifier {
     let component: ModifiedComponent
     let methodName: String

     init(_ component: ModifiedComponent, methodName: String) {
         self.component = component
         self.methodName = methodName
     }
 }

 extension GRPCMethodModifier: Visitable {
     func visit(_ visitor: SyntaxTreeVisitor) {
         visitor.addContext(GRPCMethodNameContextKey.self, value: methodName, scope: .nextComponent)
         component.visit(visitor)
     }
 }

 extension Component {
     /// Explicitly sets the name of the gRPC service that is exposed for this `Component`
     public func rpcName(_ methodName: String) -> GRPCMethodModifier<Self> {
         GRPCMethodModifier(self, methodName: methodName)
     }
 }
