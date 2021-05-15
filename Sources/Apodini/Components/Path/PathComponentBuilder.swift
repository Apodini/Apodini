/// '_functionBuilder' to build `PathComponent`s
#if swift(>=5.4)
@resultBuilder
public enum PathComponentBuilder {}
#else
@_functionBuilder
public enum PathComponentBuilder {}
#endif
extension PathComponentBuilder {
    /// Return any array of `PathComponent`s directly
    public static func buildBlock(_ paths: PathComponent...) -> [PathComponent] {
        paths
    }
}
