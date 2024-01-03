//                   
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//              

import Apodini
import FluentKit
import Foundation
import ApodiniNetworking

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
    
    func executeUpdate(on database: any Database) -> EventLoopFuture<Model> {
        Model
            .find(modelID, on: database)
            .unwrap(orError: HTTPAbortError(status: .notFound))
            .flatMap { foundModel -> EventLoopFuture<Model> in
                var foundModel = foundModel
                if let model = model {
                    //As there is a model provided by the request,
                    //it can be just updated in the db
                    foundModel.update(model)
                } else {
                    self.executeUpdateWithParameters(on: &foundModel)
                }
                return foundModel
                    .update(on: database)
                    .transform(to: foundModel)
            }
    }
    
    /// Private method to handle the update of the `DatabaseModel` when only some properties are provided by the request.
    /// It iterates over all properties of the model and updates all which are found in the request.
    private func executeUpdateWithParameters(on model: inout Model) {
        for child in Mirror(reflecting: model).children {
            guard let visitable = child.value as? any UpdatableFieldProperty,
                  let label = child.label else {
                continue
            }
            let fieldKey = Model.fieldKey(for: label.trimmed())
            if let value = self.properties[fieldKey] {
                do {
                    try visitable.accept(ConcreteUpdatableFieldPropertyVisitor(updater: value))
                } catch {
                    Application.logger.error("Trying to update the property \(visitable) of the model \(model) with \(value): \(error.localizedDescription)")
                }
            }
        }
    }
}

fileprivate extension String {
    /// Returns the string reduced by `_`. This is needed as `Mirror` shows the names of a types properties with a prefixed `_`.
    /// To use them in the `Updater` correctly, this needs to be removed.
    func trimmed() -> Self {
        self.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "_", with: "")
    }
}
