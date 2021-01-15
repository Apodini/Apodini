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
    
    @Parameter<[String: AnyCodable]>
    private var parameters: [String: AnyCodable]
    
    @Parameter
    private var object: Model?
    
    @Parameter(.http(.path))
    var id: Model.IDValue
    
    public func handle() -> EventLoopFuture<Model> {
        print("handle")
        print(parameters)
        var updater = Updater<Model>(parameters)
        updater.model = object
        updater.modelID = id
        
        return updater.executeUpdate(on: database)
    }
}

internal struct Updater<Model: DatabaseModel> {
    var properties: [FieldKey: AnyCodable]?
    
    var model: Model?
    var modelID: Model.IDValue?
    
    init(_ properties: [String: AnyCodable]?) {
        if let properties = properties {
            self.properties = properties.reduce(into: [FieldKey: AnyCodable](), { result, entry in
                result[Model.fieldKey(for: entry.0)] = entry.1
            })
        }
    }
    
    func executeUpdate(on database: Database) -> EventLoopFuture<Model> {
        if let model = model {
            return Model.find(modelID, on: database)
                .unwrap(orError: Abort(.notFound))
                .map { foundModel -> Model in
                    foundModel.update(model)
                    _ = foundModel.update(on: database).transform(to: model)
                    return model
                }
        } else {
            return Model.find(modelID, on: database)
                .unwrap(orError: Abort(.notFound)).map { model -> Model in
                    var model = model
                    print(model)
                    for child in Mirror(reflecting: model).children {
                        guard let visitable = child.value as? UpdatableFieldProperty,
                              let label = child.label,
                              let properties = properties else { continue }
                        let fieldKey = Model.fieldKey(for: label.trimmed())
                        print(properties[fieldKey])
                        if let value = properties[fieldKey] {
                            if visitable.accept(ConcreteUpdatableFieldPropertyVisitor(updater: value)) {
                                model.update(on: database)
                                return model
                            } else {
                                fatalError("the updater was unable to update single properties of")
                            }
                        }
                    }
                    return model
            }
        }
    }
}

fileprivate extension String {
    
    func trimmed() -> Self {
        self.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "_", with: "")
    }
    
}
