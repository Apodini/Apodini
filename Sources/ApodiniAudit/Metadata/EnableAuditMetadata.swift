import Apodini

public struct EnableAuditMetadata: ComponentMetadataDefinition {
    public typealias Key = EnableAuditContextKey
    
    public let value: BestPractice.Type
}

public struct EnableAuditContextKey: OptionalContextKey {
    public typealias Value = BestPractice.Type
}
