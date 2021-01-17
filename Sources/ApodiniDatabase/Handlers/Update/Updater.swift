import Apodini
import Fluent
@_implementationOnly import Vapor

/// An Updater classed which is used internally by the `Update` handler. It can take model or single parameters of a model to update
/// the model found in the database.
internal struct Updater<Model: DatabaseModel> {
    var properties: [FieldKey: TypeContainer] = [:]
    
    var model: Model?
    var modelID: Model.IDValue?
    
    init(_ properties: [String: TypeContainer], model: Model?, modelId: Model.IDValue) {
        self.properties = properties.reduce(into: [FieldKey: TypeContainer]()) { result, entry in
            result[Model.fieldKey(for: entry.0)] = entry.1
        }
        self.model = model
        self.modelID = modelId
    }
    
    func executeUpdate(on database: Database) -> EventLoopFuture<Model> {
        if let model = model {
            return Model.find(modelID, on: database)
                .unwrap(orError: Abort(.notFound))
                .map { foundModel -> Model in
                    foundModel.update(model)
                    _ = foundModel.update(on: database).transform(to: model)
                    return model
                }
        } else {
            return Model.find(modelID, on: database)
                .unwrap(orError: Abort(.notFound))
                .map { model -> Model in
                    for child in Mirror(reflecting: model).children {
                        guard let visitable = child.value as? UpdatableFieldProperty,
                              let label = child.label
                        else { continue }
                        let fieldKey = Model.fieldKey(for: label.trimmed())
                        if let value = properties[fieldKey] {
                            if visitable.accept( ConcreteUpdatableFieldPropertyVisitor(updater: value) ) {
                                _ = model.update(on: database).transform(to: model)
                                return model
                            } else {
                                fatalError("An error occurred while updating single parameters the model ")
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
