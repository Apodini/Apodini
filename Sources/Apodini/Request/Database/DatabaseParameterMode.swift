import Foundation

public enum DatabaseParameterMode: PropertyOption {
    case context(DatabaseInjectionContext)
    
    var injectionContext: DatabaseInjectionContext {
        switch self {
        case .context(let context):
            return context
        }
    }
}

extension PropertyOptionKey where PropertyNameSpace == ParameterOptionNameSpace, Option == DatabaseParameterMode {
    static let databaseContext = PropertyOptionKey<ParameterOptionNameSpace, DatabaseParameterMode>()
}

extension AnyPropertyOption where PropertyNameSpace == ParameterOptionNameSpace {
    public static func database(_ context: DatabaseInjectionContext) -> AnyPropertyOption<ParameterOptionNameSpace> {
        AnyPropertyOption(key: .databaseContext, value: .context(context))
    }
}
