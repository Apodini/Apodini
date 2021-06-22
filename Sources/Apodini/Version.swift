//
//  Version.swift
//  Apodini
//
//  Created by Paul Schmiedmayer on 6/26/20.
//


/// A `Version` can be  used to specify the version of a Web API using semantic versioning
public struct Version: Decodable {
    /// Default values for a `Version`
    public enum Defaults {
        /// The default prefix
        public static let prefix: String = "v"
        /// The default major version
        public static let major: UInt = 1
        /// The default major minor
        public static let minor: UInt = 0
        /// The default major patch
        public static let patch: UInt = 0
    }
    
    
    /// The version prefix
    public let prefix: String
    /// The major version number
    public let major: UInt
    /// The minor version number
    public let minor: UInt
    /// The patch version number
    public let patch: UInt
    
    
    /// - Parameters:
    ///   - prefix: The version prefix
    ///   - major: The major version number
    ///   - minor: The minor version number
    ///   - patch: The patch version number
    public init(prefix: String = Defaults.prefix,
                major: UInt = Defaults.major,
                minor: UInt = Defaults.minor,
                patch: UInt = Defaults.patch) {
        self.prefix = prefix
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}


extension Version: _PathComponent {
    public var description: String {
        "\(prefix)\(major)"
    }

    func append<Parser: PathComponentParser>(to parser: inout Parser) {
        parser.visit(self)
    }
}

public struct APIVersionContextKey: OptionalContextKey {
    public typealias Value = Version
}
