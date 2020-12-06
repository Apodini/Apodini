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

class WebSocketSemanticModelBuilder: SemanticModelBuilder {
    
    private let router: WebSocketInfrastructure.Router
    
    init(_ app: Application, on router: WebSocketInfrastructure.Router? = nil) {
        self.router = router ?? VaporWSRouter(app)
        super.init(app)
    }
    
    override func register<C>(component: C, withContext context: Context) where C: Component {
        super.register(component: component, withContext: context)
        
        #if DEBUG
//        self.printWebSocketInfo(of: component, withContext: context)
        #endif
        
        let defaultInput = AnyInput(from: component)
        
        self.router.register({ (input: AnyPublisher<AnyInput, Never>) -> (defaultInput: AnyInput, output: AnyPublisher<Message<C.Response>, Error>) in
            var component = component
            let defaultInput = defaultInput
            
            let output = input.tryMap { (i: AnyInput) throws -> Message<C.Response> in
                print("published input \(i)")
                do {
                    let info = try typeInfo(of: C.self)

                    for property in info.properties {
                        if var child = (try property.get(from: component)) as? Updatable {
                            assert(((try? typeInfo(of: property.type).kind) ?? .none) == .struct, "Updatable \(property.name) on element \(info.name) must be a struct")
                            if let ip = i.parameters[property.name.trimmingCharacters(in: ["_"])] {
                                if let v = (ip as? WebSocketInfrastructure.Parameter<String>)?.value {
                                    child.update(from: v)
                                } else {
                                    fatalError("tempoarary: should be string")
                                }
                            } else {
                                fatalError("Missing property \(property.name.trimmingCharacters(in: ["_"])) on Input.")
                            }
                            try property.set(value: child, on: &component)
                        }
                    }
                } catch {
                    fatalError("Updating element \(component) failed.")
                }
                
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

struct WebSocketPathBuilder: PathBuilder {
    private var pathComponents: [String] = []
    
    
    fileprivate var pathIdentifier: String {
        pathComponents
            .map { pathComponent in
                pathComponent.description
            }
            .joined(separator: "/")
    }
    
    
    init(_ pathComponents: [PathComponent]) {
        for pathComponent in pathComponents {
            if let pathComponent = pathComponent as? _PathComponent {
                pathComponent.append(to: &self)
            }
        }
    }
    
    
    mutating func append(_ string: String) {
        let pathComponent = string.lowercased()
        pathComponents.append(pathComponent)
    }
    
    mutating func append<T>(_ identifiier: Identifier<T>) where T: Identifiable {
        let pathComponent = identifiier.identifier
        pathComponents.append(pathComponent)
    }
}


extension AnyInput {
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

protocol WSInputRepresentable {
    func input() -> InputParameter
}

extension Parameter: WSInputRepresentable {
    
    func input() -> InputParameter {
        WebSocketInfrastructure.Parameter<Element>(mutability: .variable, necessity: .optional)
    }
    
}

protocol Updatable {
    mutating func update(from: Any?)
}

extension Parameter: Updatable {
    mutating func update(from element: Any?) {
        if let e = element as? Element {
            self.element = e
        } else if let e = element as? Element? {
            self.element = e
        } else {
            fatalError("Mismatching type when updating \(self) with \(element ?? "nil")")
        }
    }
}

//struct AnyParameterUpdater: Updater, InputParameter {
//
//    private var updater: Updater
//    private var inputParameter: InputParameter
//
//    init<T: Codable>(_ p: inout ParameterUpdater<T>) {
//        self.updater = p
//        self.inputParameter = p
//    }
//
//    mutating func update() {
//        updater.update()
//    }
//
//    mutating func update(_ value: Any) -> ParameterUpdateResult {
//        inputParameter.update(value)
//    }
//
//    func check() -> ParameterCheckResult {
//        inputParameter.check()
//    }
//
//}
//
//struct ParameterUpdater<T: Codable>: Updater, InputParameter {
//
//    private var input: WebSocketInfrastructure.Parameter<T>
//
//    private var wrapper: Parameter<T>
//
//    init(input: WebSocketInfrastructure.Parameter<T>, wrapper: inout Parameter<T>) {
//        self.input = input
//        self.wrapper = wrapper
//    }
//
//    mutating func update() {
//        wrapper.element = input.value
//    }
//
//    mutating func update(_ value: Any) -> ParameterUpdateResult {
//        input.update(value)
//    }
//
//    func check() -> ParameterCheckResult {
//        input.check()
//    }
//}
//
