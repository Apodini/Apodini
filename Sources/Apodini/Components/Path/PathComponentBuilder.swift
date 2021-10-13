/// '_functionBuilder' to build `PathComponent`s
@resultBuilder
public enum PathComponentBuilder {
    /// Return any array of `PathComponent`s directly
    public static func buildBlock(_ paths: PathComponent...) -> [PathComponent] {
        paths
    }
}
