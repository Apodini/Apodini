import Apodini

public struct DisableAuditMetadata: ComponentMetadataDefinition {
    public typealias Key = DisableAuditContextKey
    
    public let value: BestPractice.Type
}

public struct DisableAuditContextKey: OptionalContextKey {
    public typealias Value = BestPractice.Type
}
