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
    
    @Parameter<[String: AnyCodable]>
    private var parameters: [String: AnyCodable]
    
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
        var updater = Updater<Model>()
        updater.properties = parameters
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
    var properties: [String: AnyCodable]?
    
    var type: Model.Type
    
    var model: Model?
    var modelID: Model.IDValue?
    
    private var singlePropertiesOnly: Bool {
        properties != nil && model == nil
    }
    
    init(_ properties: [String: AnyCodable]?, for type: Model.Type) {
        self.properties = properties
        self.type = type
    }
    
    init(_ model: Model, for id: Model.IDValue?) {
        self.model = model
        self.type = Model.self
        self.modelID = id
    }
    
    init() {
        self.type = Model.self
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
        } else {
            print(modelID)
//            model = Model()
            Model.find(modelID, on: database)
                .unwrap(orError: Abort(.notFound)).map({ model -> Model in
                    var varModel = model
                    for child in Mirror(reflecting: model).children {
                        print(child)
                        if let visitable = child.value as? VisitableFieldProperty {
                            let test = visitable.accept(ConcreteTypeVisitor())
                            print(test)
                        }
                    }

                    return varModel
                })
        }
    }
    
    
    
}

struct AnyCodable: Codable {
    enum DecodeableType {
        case string, bool, int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64, uuid, float, double
    }
    
    private var types: [DecodeableType] {
        [.string, .bool, .int, .int8, .int16, .int32, .int64, .uint, .uint8, .uint16, .uint32, .uint64, .uuid, .float, .double]
    }
    
    var wrappedValue: Codable?
    
    init(_ wrappedValue: Codable) {
        self.wrappedValue = wrappedValue
    }
    
    func encode(to encoder: Encoder) throws {
        try wrappedValue?.encode(to: encoder)
    }
    
    init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.singleValueContainer()
        for type in types {
            guard wrappedValue == nil else {
                return
            }
            do {
                switch type {
                case .string:
                    self.wrappedValue = try values.decode(String.self)
                case .bool:
                    self.wrappedValue = try values.decode(Bool.self)
                case .int:
                    self.wrappedValue = try values.decode(Int.self)
                case .int8:
                    self.wrappedValue = try values.decode(Int8.self)
                case .int16:
                    self.wrappedValue = try values.decode(Int16.self)
                case .int32:
                    self.wrappedValue = try values.decode(Int32.self)
                case .int64:
                    self.wrappedValue = try values.decode(Int64.self)
                case .uint:
                    self.wrappedValue = try values.decode(UInt.self)
                case .uint8:
                    self.wrappedValue = try values.decode(UInt8.self)
                case .uint16:
                    self.wrappedValue = try values.decode(UInt16.self)
                case .uint32:
                    self.wrappedValue = try values.decode(UInt32.self)
                case .uint64:
                    self.wrappedValue = try values.decode(UInt64.self)
                case .uuid:
                    self.wrappedValue = try values.decode(UUID.self)
                case .double:
                    self.wrappedValue = try values.decode(Double.self)
                case .float:
                    self.wrappedValue = try values.decode(Float.self)
                }
            } catch(let error) {
                print(error.localizedDescription)
            }
        }
    }
    
    init() {
        wrappedValue = nil
    }
    
    func typed<T: Codable>(_ type: T.Type = T.self) -> T? {
             guard let anyCodableWrappedValue = wrappedValue as? AnyCodable else {
                 return wrappedValue as? T
             }
             return anyCodableWrappedValue.typed(T.self)
    }
    
    
}
