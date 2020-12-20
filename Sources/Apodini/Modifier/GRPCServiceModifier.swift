//
 //  GRPCServiceModifier.swift
 //
 //
 //  Created by Moritz Schüll on 04.12.20.
 //

 struct GRPCServiceNameContextKey: ContextKey {
     static var defaultValue = ""

     static func reduce(value: inout String, nextValue: () -> String) {
         value = nextValue()
     }
 }

 public struct GRPCServiceModifier<ModifiedComponent: Component>: Modifier {
     let component: ModifiedComponent
     let serviceName: String

     init(_ component: ModifiedComponent, serviceName: String) {
         self.component = component
         self.serviceName = serviceName
     }
 }

 extension GRPCServiceModifier: Visitable {
     func visit(_ visitor: SyntaxTreeVisitor) {
         visitor.addContext(GRPCServiceNameContextKey.self, value: serviceName, scope: .nextComponent)
         component.visit(visitor)
     }
 }

 extension Component {
     /// Explicitly sets the name of the gRPC service that is exposed for this `Component`
     public func serviceName(_ serviceName: String) -> GRPCServiceModifier<Self> {
         GRPCServiceModifier(self, serviceName: serviceName)
     }
 }
