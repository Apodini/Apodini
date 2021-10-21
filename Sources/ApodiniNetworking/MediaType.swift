import ApodiniUtils

/// A HTTP Media Type, as defined in [RFC6838](https://datatracker.ietf.org/doc/html/rfc6838)
public struct HTTPMediaType: HTTPHeaderFieldValueCodable, Equatable, Hashable {
    public let type: String
    public let subtype: String
    public let parameters: [String: String]
    
    
    public init(type: String, subtype: String, parameters: [String: String] = [:]) {
        precondition(!type.isEmpty && !subtype.isEmpty, "Invalid input")
        self.type = type
        self.subtype = subtype
        self.parameters = parameters
    }
    
    public init?(string: String) {
        guard let typeSubtypeSeparatorIdx = string.firstIndex(of: "/") else {
            return nil
        }
        self.type = String(string[..<typeSubtypeSeparatorIdx])
        guard let firstParamIdx = string.firstIndex(of: ";", after: typeSubtypeSeparatorIdx) else {
            // No parameters, meaning that the entire rest of the string is the subtype
            self.subtype = String(string.suffix(from: typeSubtypeSeparatorIdx).dropFirst())
            self.parameters = [:]
            return
        }
        self.subtype = String(string[typeSubtypeSeparatorIdx..<firstParamIdx].dropFirst())
        var parameters: [String: String] = [:]
        let rawParameters = string[firstParamIdx...].split(separator: ";").map { $0.trimmingLeadingAndTrailingWhitespace() }
        for component in rawParameters {
            let componentComponents = component.components(separatedBy: "=")
            guard componentComponents.count == 2 else {
                // We're expecting two components were produced from splitting the component into its components.
                return nil
            }
            parameters[componentComponents[0]] = componentComponents[1]
        }
        self.parameters = parameters
    }
    
    
    public init?(httpHeaderFieldValue: String) {
        self.init(string: httpHeaderFieldValue)
    }
    
    
    public func encodeToHTTPHeaderFieldValue() -> String {
        var retval = "\(type)/\(subtype)"
        for (key, value) in parameters {
            retval.append("; \(key)=\(value)")
        }
        return retval
    }
    
    
    /// The suffix of the subtype
    public var suffix: String? {
        if let idx = subtype.firstIndex(of: "+") {
            return String(subtype[idx...])
        } else {
            return nil
        }
    }
    
    
    /// The media type's subtype, with the suffix removed if applicable
    public var subtypeWithoutSuffix: String {
        if let idx = subtype.firstIndex(of: "+") {
            return String(subtype[..<idx])
        } else {
            return subtype
        }
    }
    
    
    /// Whether the two media types are equal when ignoring their suffixes (if applicable)
    public func equalsIgnoringSuffix(_ other: HTTPMediaType) -> Bool {
        return self.subtypeWithoutSuffix == other.subtypeWithoutSuffix
    }
}


extension HTTPMediaType {
    public static let html = HTTPMediaType(type: "text", subtype: "html", parameters: ["charset": "utf-8"])
    public static let json = HTTPMediaType(type: "application", subtype: "json", parameters: ["charset": "utf-8"])
    public static let xml = HTTPMediaType(type: "application", subtype: "xml", parameters: ["charset": "utf-8"])
    public static let gRPC = HTTPMediaType(type: "application", subtype: "grpc")
    public static let pdf = HTTPMediaType(type: "application", subtype: "pdf")
    // TODO add some more
    
//    public enum CharsetParameterValue: String {
//        case utf8 = "utf-8"
//    }
//
//    public static func json(charset: CharsetParameterValue = .utf8) -> Self {
//        HTTPMediaType(type: "application", subtype: "json", parameters: ["charset": charset.rawValue])
//    }
}

