//
//  RESTVisitor.swift
//  
//
//  Created by Paul Schmiedmayer on 6/26/20.
//

import Apodini


public class RESTVisitor: Visitor {
    struct RESTPathBuilder: PathBuilder {
        var pathDescription: String = ""
        
        mutating func append(_ string: String) {
            pathDescription.append("/\(string.lowercased())")
        }
        
        mutating func append<T>(_ identifiier: Identifier<T>) where T : Identifiable {
            pathDescription.append("/$\(String(describing: T.self).uppercased())")
        }
    }
    
    public override init() {
        super.init()
    }
    
    public override func register<C>(component: C) where C: Component {
        super.register(component: component)
        
        var restPathBuilder = RESTPathBuilder()
        for pathComponent in getContextValue(for: PathComponentContextKey.self) {
            pathComponent.append(to: &restPathBuilder)
        }
        let httpType = getContextValue(for: HTTPMethodContextKey.self)
        let returnType: Codable.Type = {
            let modifiedResponseType = getContextValue(for: ResponseContextKey.self)
            if modifiedResponseType != Never.self {
                return modifiedResponseType
            } else {
                return C.Response.self
            }
        }()
        
        print("\(restPathBuilder.pathDescription) \(httpType.description) -> \(returnType)")
        
        super.finishedRegisteringContext()
    }
}
