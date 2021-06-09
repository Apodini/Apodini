//
// Created by Andreas Bauer on 06.06.21.
//

struct Platform: OptionSet {
    let rawValue: UInt8

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    static let macOS = Platform(rawValue: 1 << 0)
    static let linux = Platform(rawValue: 1 << 1)
    static let watchOS = Platform(rawValue: 1 << 2)
    static let iOS = Platform(rawValue: 1 << 3)
    static let tvOS = Platform(rawValue: 1 << 4)
    static let windows = Platform(rawValue: 1 << 5)

    static func exclude(_ platform: Platform) -> Platform {
        Platform(rawValue: ~platform.rawValue)
    }

    static func currentPlatform() -> Platform {
        #if os(macOS)
        return Platform.macOS
        #elseif os(Linux)
        return Platform.linux
        #elseif os(iOS)
        return Platform.iOS
        #elseif os(watchOS)
        return Platform.watchOS
        #elseif os(tvOS)
        return Platform.tvOS
        #elseif os(Windows)
        return Platform.windows
        #else
        fatalError("Unexpected platform")
        #endif
    }
}

extension Platform: CustomStringConvertible {
    public var description: String {
        switch self {
        case .macOS:
            return "macOS"
        case .linux:
            return "linux"
        case .iOS:
            return "iOS"
        case .watchOS:
            return "watchOS"
        case .tvOS:
            return "tvOS"
        case .windows:
            return "windows"
        default:
            return "UNKNOWN"
        }
    }
}
