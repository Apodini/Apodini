//
// Created by Lorena Schlesinger on 23.01.21.
//

@_implementationOnly import OpenAPIKit

struct OpenAPIStorageKey: StorageKey {
    typealias Value = OpenAPI.Document
}
