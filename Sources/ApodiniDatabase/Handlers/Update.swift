import Foundation
import Fluent
@_implementationOnly import Vapor
import Apodini
import Runtime

/// A Handler that updates a `DatabaseModel` with the given id with the new object of the request.
/// It uses the database that has been specified in the `DatabaseConfiguration`.
public struct Update<Model: DatabaseModel>: Handler {
    @Apodini.Environment(\.database)
    private var database: Fluent.Database
    
//    @Properties
//    private var properties: [String: Apodini.Property]
    
    @Parameter<[String: AnyConcreteCodable]>
    private var parameters: [String: AnyConcreteCodable]
    
    @Parameter
    private var object: Model?
    
    @Parameter(.http(.path))
    var id: Model.IDValue
    
    private var modelInfo: [ModelInfo] {
        QueryBuilder.info(for: Model.self)
    }
    
    let modelIdentifier: String = UUID().uuidString
    
    init() {
//        var elements = QueryBuilder.info(for: Model.self).reduce(into: [String: Parameter<String?>](), { (result, modelInfo) in
//            result[modelInfo.key.description] = Parameter<String?>(modelInfo.key.description, .http(.body))
//        })

//        _properties = Properties(wrappedValue: elements)
    }
    
//    public func handle() -> EventLoopFuture<T> {
    public func handle() -> String {
        print("handle")
        print(parameters)
        var updater = Updater<Model>(parameters)
        updater.model = object
        updater.modelID = id
        
        updater.executeUpdate(on: database)
//        let updater = Updater(parameters, for: Model.self)
//        updater.executeUpdate(on: database)
//        if let object = object {
//            Model.find(id, on: database)
//                .unwrap(orError: Abort(.notFound))
//                .map { model -> Model in
//                    model.update(object)
//                    _ = model.update(on: database)
//                    return model
//                }
//            return "success"
//        } else {
//            print(parameters.compactMapValues({ $0.typed($0) }))
//            return "test"
//        }
        return "success"
    }
}

internal struct Updater<Model: DatabaseModel> {
    var properties: [FieldKey: AnyConcreteCodable]?
    
    var model: Model?
    var modelID: Model.IDValue?
    
    private var singlePropertiesOnly: Bool {
        properties != nil && model == nil
    }
    
    init(_ properties: [String: AnyConcreteCodable]?) {
        if let properties = properties {
            self.properties = properties.reduce(into: [FieldKey: AnyConcreteCodable](), { result, entry in
                result[Model.fieldKey(for: entry.0)] = entry.1
            })
        }
    }
    
    init(_ model: Model, for id: Model.IDValue?) {
        self.model = model
        self.modelID = id
    }
    
    init() {
//        self.type = Model.self
    }
    
    func executeUpdate(on database: Database) {
        if !singlePropertiesOnly {
//            Model.find(modelID, on: database)
//                .unwrap(orError: Abort(.notFound))
//                .map { model -> Model in
//                    model.update(object)
//                    _ = model.update(on: database)
//                    return model
//                }
            print(model)
            print(properties)
        } else {
            print(modelID)
//            model = Model()
            Model.find(modelID, on: database)
                .unwrap(orError: Abort(.notFound)).map({ model -> Model in
                    var model = model
                    print(model)
                    for child in Mirror(reflecting: model).children {
                        guard let visitable = child.value as? UpdatableFieldProperty, let label = child.label, let properties = properties else { continue }
                        let fieldKey = Model.fieldKey(for: label.trimmed())
                        print(properties[fieldKey])
                        if let value = properties[fieldKey] {
                            let _ 
                        }
                        
                        if let visitable = child.value as? UpdatableFieldProperty {
                            print(child.label!)
                            
                            for (key,property) in properties {
                                let abc = visitable.accept(ConcreteUpdatableFieldPropertyVisitor(updater: property))
                                print(abc)
                                print((visitable as? FieldProperty<Model, Int>)?.value)
                            }
                        }
//                        if let visitable = child.value as? VisitableFieldProperty {
//                            let test = visitable.accept(ConcreteTypeVisitor())
//                            if let updatable = child.value as? UpdatableFieldProperty {
//                                for (key,property) in properties! {
//                                    let abc = updatable.accept(ConcreteUpdatableFieldPropertyVisitor(updater: property))
//                                    print(abc)
//                                    print((updatable as? FieldProperty<Model, Int>)?.value)
//                                }
//                            }
//                        }
                    }
                    print(model)
                    return model
                })
        }
    }
}

extension String {
    
    func trimmed() -> Self {
        self.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "_", with: "")
    }
    
}
