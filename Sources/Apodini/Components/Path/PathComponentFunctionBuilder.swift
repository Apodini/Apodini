/// '_functionBuilder' to build `PathComponent`s
@_functionBuilder
public enum PathComponentFunctionBuilder {
    /// Return any array of `PathComponent`s directly
    public static func buildBlock(_ paths: PathComponent...) -> [PathComponent] {
        paths
    }
}
