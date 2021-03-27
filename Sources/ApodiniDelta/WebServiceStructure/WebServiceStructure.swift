//
//  File.swift
//  
//
//  Created by Eldi Cano on 22.03.21.
//

import Apodini

struct WebServiceStructure {

    var version: Version?
    var services: [Service] = []
    var schemaBuilder = SchemaBuilder()

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

        version = try container.decode(Version?.self, forKey: .version)
        services = try container.decode([Service].self, forKey: .services)
        let schemas = try container.decode(Set<Schema>.self, forKey: .schemas)
        schemaBuilder = SchemaBuilder()
        schemaBuilder.addSchemas(schemas)
    }

}
