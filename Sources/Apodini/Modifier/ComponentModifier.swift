protocol Modifier: Component {
    associatedtype ModifiedComponent: Component
    
    var component: ModifiedComponent { get }
}
