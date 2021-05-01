import Foundation

struct DeltaJSON {
    func jsonString<E: Encodable>(_ type: E.Type) throws -> String {
        try TypeContainer(type: type).jsonString
    }
    
    func instance<C: Codable>(_ type: C.Type) throws -> C {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.iSO8601DateFormatter)
        let data = try jsonString(C.self).data(using: .utf8) ?? Data()
        return try decoder.decode(C.self, from: data)
    }
}
