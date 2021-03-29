//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Apodini

struct WebServiceStructure {

    var version: Version!
    var services: [Service] = []
    var schemaBuilder = SchemaBuilder()

    var schemas: [Schema] {  Array(schemaBuilder.schemas) }

    mutating func addEndpoint<H: Handler>(_ endpoint: Endpoint<H>) {
        if version == nil {
            version = endpoint.context.get(valueFor: APIVersionContextKey.self)
        }

        let parameters = endpoint.parameters.serviceParameters(with: &schemaBuilder)

        let response = schemaBuilder.build(for: endpoint.responseType) ?? .empty

        let service = Service(
            handlerName: endpoint.description,
            handlerIdentifier: endpoint.identifier,
            operation: endpoint.operation,
            absolutePath: endpoint.absolutePath,
            parameters: parameters,
            response: response
        )

        services.append(service)
    }

}

extension WebServiceStructure: Codable {

    private enum CodingKeys: String, CodingKey {
        case version
        case services
        case schemas
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(services, forKey: .services)
        try container.encode(schemaBuilder.schemas, forKey: .schemas)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        version = try container.decode(Version.self, forKey: .version)
        services = try container.decode([Service].self, forKey: .services)
        let schemas = try container.decode(Set<Schema>.self, forKey: .schemas)
        schemaBuilder = SchemaBuilder()
        schemaBuilder.addSchemas(schemas)
    }

}

extension WebServiceStructure: ComparableObject {

    var deltaIdentifier: DeltaIdentifier {
        .init(version.description)
    }

    func evaluate(result: ChangeContextNode, embeddedInCollection: Bool) -> Change? {
        let changes = [
            services.evaluate(node: result),
            schemas.evaluate(node: result)
        ].compactMap { $0 }

        guard !changes.isEmpty else { return nil }

        return .compositeChange(location: Self.changeLocation, changes: changes)
    }

    func compare(to other: WebServiceStructure) -> ChangeContextNode {
        let context = ChangeContextNode()

        context.register(result: compare(\.services, with: other), for: Service.self)
        context.register(result: compare(\.schemas, with: other), for: Schema.self)

        return context
    }

    // Required from ComparableObject protocol, however not used for WebServiceStructure
    static func == (lhs: WebServiceStructure, rhs: WebServiceStructure) -> Bool { false }
    func hash(into hasher: inout Hasher) {}
}
