protocol PathComponent {}

extension String: PathComponent {}

struct Identifier<T: Identifiable>: PathComponent {}
