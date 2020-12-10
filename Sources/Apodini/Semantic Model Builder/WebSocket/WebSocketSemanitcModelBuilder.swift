//
//  WebSocketSemanticModelBuilder.swift
//
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Vapor
import WebSocketInfrastructure
import OpenCombine
import Runtime

// MARK: WebSocketSemanticModelBuilder
class WebSocketSemanticModelBuilder: SemanticModelBuilder {
    
    private let router: WebSocketInfrastructure.Router
    
    init(_ app: Application, on router: WebSocketInfrastructure.Router? = nil) {
        self.router = router ?? VaporWSRouter(app)
        super.init(app)
    }
    
    override func register<C>(component: C, withContext context: Context) where C: Component {
        super.register(component: component, withContext: context)
        
        #if DEBUG
        self.printWebSocketInfo(of: component, withContext: context)
        #endif
        
        let defaultInput = AnyInput(from: component)
        
        self.router.register({ (input: AnyPublisher<AnyInput, Never>) -> (defaultInput: AnyInput, output: AnyPublisher<Message<C.Response>, Error>) in
            var component = component
            let defaultInput = defaultInput
            
            let output = input.tryMap { (i: AnyInput) throws -> Message<C.Response> in
                
                update(&component, from: i.parameters.values.map({ p in
                    return p as! IdentifiableInputParameter
                }))
                
                return .send(component.handle())
            }
            return (defaultInput: defaultInput, output: output.eraseToAnyPublisher())
        }, on: WebSocketPathBuilder(context.get(valueFor: PathComponentContextKey.self)).pathIdentifier)
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

// MARK: WSInputRepresentable
fileprivate protocol WSInputRepresentable {
    func input() -> IdentifiableInputParameter
}

extension Parameter: WSInputRepresentable {
    
    fileprivate func input() -> IdentifiableInputParameter {
        let m: WebSocketInfrastructure.Mutability = self.option(for: .mutability) == .constant ? .constant : .variable
        
        if Element.self is ExpressibleByNilLiteral.Type || self.defaultValue != nil {
            return IdentifiableInputParameter(inputParameter: WebSocketInfrastructure.Parameter<Element>(mutability: m, necessity: .optional), id: self.id)
        } else  {
            return IdentifiableInputParameter(inputParameter: WebSocketInfrastructure.Parameter<Element>(mutability: m, necessity: .required), id: self.id)
        }
    }
    
}


// MARK: Input Helpers
fileprivate extension AnyInput {
    init<E>(from element: E) {
        var parameters: [String: InputParameter] = [:]
        do {
            let info = try typeInfo(of: E.self)

            for property in info.properties {
                if let child = (try property.get(from: element)) as? WSInputRepresentable {
                    precondition(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "WSInputRepresentable \(property.name) on element \(info.name) must be a struct")
                    parameters[property.name.trimmingCharacters(in: ["_"])] = child.input()
                }
            }
        } catch {
            fatalError("Deriving an Input from element \(element) failed.")
        }

        self.init(parameters: parameters)
    }
}

extension WebSocketInfrastructure.Parameter: UpdatingInputParameter {
    func update(_ u: inout UpdatableProperty) {
        u.update(with: self.value)
    }
}

fileprivate protocol UpdatingInputParameter: InputParameter, Updater {}

fileprivate struct IdentifiableInputParameter: InputParameter, IdentifiableUpdater {
    
    fileprivate var inputParameter: UpdatingInputParameter
    let id: UUID
    
    
    init<T>(inputParameter: WebSocketInfrastructure.Parameter<T>, id: UUID) {
        self.id = id
        self.inputParameter = inputParameter
    }
    
    mutating func update(_ value: Any) -> ParameterUpdateResult {
        inputParameter.update(value)
    }
    
    nonmutating func check() -> ParameterCheckResult {
        inputParameter.check()
    }
    
    mutating func apply() {
        inputParameter.apply()
    }
    
    func update(_ u: inout UpdatableProperty) {
        inputParameter.update(&u)
    }
    
}
