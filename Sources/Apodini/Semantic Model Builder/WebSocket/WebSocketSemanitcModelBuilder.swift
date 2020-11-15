//
//  WebSocketSemanticModelBuilder.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor

class WebSocketSemanticModelBuilder: SemanticModelBuilder {
    
    override init(_ app: Application) {
        super.init(app)
    }
    
    override func register<C>(component: C, withContext context: Context) where C: Component {
        super.register(component: component, withContext: context)
        
        
        #if DEBUG
        self.printWebSocketInfo(of: component, withContext: context)
        #endif
    }
    
    
    private func printWebSocketInfo<C>(of component: C, withContext context: Context) where C: Component {
        print("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv")
        print("Component: ------")
        print(component)
        print("Context: --------")
        print("id: \(context.get(valueFor: PathComponentContextKey.self))")
        print("onSuccess: \(context.get(valueFor: WebSocketSuccessBehaviorContextKey.self))")
        print("onError: \(context.get(valueFor: WebSocketErrorBehaviorContextKey.self))")
        print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")
    }
    
}
