enum HTTPType: String, LosslessStringConvertible {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    
    
    var description: String {
        return rawValue
    }
    
    
    init?(_ description: String) {
        switch description.lowercased() {
        case HTTPType.get.rawValue:
            self = .get
        case HTTPType.post.rawValue:
            self = .post
        case HTTPType.put.rawValue:
            self = .put
        case HTTPType.delete.rawValue:
            self = .delete
        default:
            return nil
        }
    }
}
