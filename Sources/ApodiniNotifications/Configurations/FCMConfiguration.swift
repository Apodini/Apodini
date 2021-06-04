import Foundation
import FCM
import Apodini


public struct FirebaseConfiguration: Configuration {
    let configuration: FCMConfiguration
    
    
    public init(_ filePath: URL) {
        guard let json = try? String(contentsOf: filePath) else {
            fatalError("Could not read the FCMConfiguration from the file located at \(filePath)")
        }
        self.configuration = FCMConfiguration(fromJSON: json)
    }
    
    
    public func configure(_ app: Application) {
        app.fcm.configuration = configuration
    }
}
