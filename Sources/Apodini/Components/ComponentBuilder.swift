// swiftlint:disable all
// This file was automatically generated and should not be edited.

@_functionBuilder
public struct EndpointProvidingNodeBuilder {
    //public static func buildBlock() -> EmptyComponent {
    //    EmptyComponent()
    //}
    
    public static func buildBlock<Content: EndpointProvidingNode>(_ content: Content) -> Content {
        content
    }
    
    public static func buildBlock<Endpoint: EndpointNode>(_ endpoint: Endpoint) -> some EndpointProvidingNode {
        return _WrappedEndpoint(endpoint)
    }

    public static func buildEither<T: EndpointProvidingNode>(first: T) -> T {
        first
    }
    
    public static func buildEither<T: EndpointProvidingNode>(second: T) -> T {
        second
    }
    
    public static func buildIf<T: EndpointProvidingNode>(_ component: T?) -> T? {
        component
    }

    
    public static func buildBlock<T0: EndpointNode, T1: EndpointNode>(_ arg0: T0, _ arg1: T1) -> some EndpointProvidingNode {
        return TupleComponent<(_WrappedEndpoint<T0>, _WrappedEndpoint<T1>)>((_WrappedEndpoint(arg0), _WrappedEndpoint(arg1)))
    }

    public static func buildBlock<T0: EndpointNode, T1: EndpointProvidingNode>(_ arg0: T0, _ arg1: T1) -> some EndpointProvidingNode {
        return TupleComponent<(_WrappedEndpoint<T0>, T1)>((_WrappedEndpoint(arg0), arg1))
    }

    public static func buildBlock<T0: EndpointProvidingNode, T1: EndpointNode>(_ arg0: T0, _ arg1: T1) -> some EndpointProvidingNode {
        return TupleComponent<(T0, _WrappedEndpoint<T1>)>((arg0, _WrappedEndpoint(arg1)))
    }

    public static func buildBlock<T0: EndpointProvidingNode, T1: EndpointProvidingNode>(_ arg0: T0, _ arg1: T1) -> some EndpointProvidingNode {
        return TupleComponent<(T0, T1)>((arg0, arg1))
    }

    public static func buildBlock<T0: EndpointNode, T1: EndpointNode, T2: EndpointNode>(_ arg0: T0, _ arg1: T1, _ arg2: T2) -> some EndpointProvidingNode {
        return TupleComponent<(_WrappedEndpoint<T0>, _WrappedEndpoint<T1>, _WrappedEndpoint<T2>)>((_WrappedEndpoint(arg0), _WrappedEndpoint(arg1), _WrappedEndpoint(arg2)))
    }

    public static func buildBlock<T0: EndpointNode, T1: EndpointNode, T2: EndpointProvidingNode>(_ arg0: T0, _ arg1: T1, _ arg2: T2) -> some EndpointProvidingNode {
        return TupleComponent<(_WrappedEndpoint<T0>, _WrappedEndpoint<T1>, T2)>((_WrappedEndpoint(arg0), _WrappedEndpoint(arg1), arg2))
    }

    public static func buildBlock<T0: EndpointNode, T1: EndpointProvidingNode, T2: EndpointNode>(_ arg0: T0, _ arg1: T1, _ arg2: T2) -> some EndpointProvidingNode {
        return TupleComponent<(_WrappedEndpoint<T0>, T1, _WrappedEndpoint<T2>)>((_WrappedEndpoint(arg0), arg1, _WrappedEndpoint(arg2)))
    }

    public static func buildBlock<T0: EndpointNode, T1: EndpointProvidingNode, T2: EndpointProvidingNode>(_ arg0: T0, _ arg1: T1, _ arg2: T2) -> some EndpointProvidingNode {
        return TupleComponent<(_WrappedEndpoint<T0>, T1, T2)>((_WrappedEndpoint(arg0), arg1, arg2))
    }

    public static func buildBlock<T0: EndpointProvidingNode, T1: EndpointNode, T2: EndpointNode>(_ arg0: T0, _ arg1: T1, _ arg2: T2) -> some EndpointProvidingNode {
        return TupleComponent<(T0, _WrappedEndpoint<T1>, _WrappedEndpoint<T2>)>((arg0, _WrappedEndpoint(arg1), _WrappedEndpoint(arg2)))
    }

    public static func buildBlock<T0: EndpointProvidingNode, T1: EndpointNode, T2: EndpointProvidingNode>(_ arg0: T0, _ arg1: T1, _ arg2: T2) -> some EndpointProvidingNode {
        return TupleComponent<(T0, _WrappedEndpoint<T1>, T2)>((arg0, _WrappedEndpoint(arg1), arg2))
    }

    public static func buildBlock<T0: EndpointProvidingNode, T1: EndpointProvidingNode, T2: EndpointNode>(_ arg0: T0, _ arg1: T1, _ arg2: T2) -> some EndpointProvidingNode {
        return TupleComponent<(T0, T1, _WrappedEndpoint<T2>)>((arg0, arg1, _WrappedEndpoint(arg2)))
    }

    public static func buildBlock<T0: EndpointProvidingNode, T1: EndpointProvidingNode, T2: EndpointProvidingNode>(_ arg0: T0, _ arg1: T1, _ arg2: T2) -> some EndpointProvidingNode {
        return TupleComponent<(T0, T1, T2)>((arg0, arg1, arg2))
    }

}
