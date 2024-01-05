/// Namespace for IPP semantic model support.
public enum SemanticModel {
    /// Defines a value type conversion of a semantic attribute.
    ///
    /// "Sytnax" is the word used in the IPP specification for the type of an attribute.
    public struct Syntax<Value> {
        public let get: (IppAttribute) -> Value?
        public let set: (Value) -> IppAttribute?

        public init(get: @escaping (IppAttribute) -> Value?, set: @escaping (Value) -> IppAttribute?) {
            self.get = get
            self.set = set
        }
    }

    /// Provides simplified typed access to attributes on IPP requests and responses.
    public struct Attribute<Value> {
        // The name of the attribute.
        public let name: IppAttribute.Name

        /// The syntax of the attribute as specified by the IPP model.
        public let syntax: Syntax<Value>
    }

    /// Provides key-paths for simplified typed access to attributes on IPP requests and responses.
    public struct Attributes {
        public struct Operation {
            public var attributesCharset: Attribute<String> { .init(name: .attributesCharset, syntax: Syntaxes.charset) }
            public var attributesNaturalLanguage: Attribute<String> { .init(name: .attributesNaturalLanguage, syntax: Syntaxes.naturalLanguage) }
            public var printerUri: Attribute<String> { .init(name: .printerUri, syntax: Syntaxes.uri) }
            public var jobUri: Attribute<String> { .init(name: .jobUri, syntax: Syntaxes.uri) }
            public var documentUri: Attribute<String> { .init(name: .documentUri, syntax: Syntaxes.uri) }
            public var requestingUserName: Attribute<String> { .init(name: .requestingUserName, syntax: Syntaxes.name) }
            public var jobName: Attribute<String> { .init(name: .jobName, syntax: Syntaxes.name) }
            public var documentName: Attribute<String> { .init(name: .documentName, syntax: Syntaxes.name) }
            public var statusMessage: Attribute<String> { .init(name: .statusMessage, syntax: Syntaxes.text) }
            public var requestedAttributes: Attribute<[IppAttribute.Name]> { .init(name: .requestedAttributes, syntax: Syntaxes.setOfKeywords()) }
            public var documentFormat: Attribute<String> { .init(name: .documentFormat, syntax: Syntaxes.mimeMediaType) }
        }

        public let operation = Operation()
    }

    /// Collection of syntaxes for IPP attributes.
    public enum Syntaxes {
        public static var charset: Syntax<String> { .init(get: { $0.value.asString }, set: { .init(.charset($0)) }) }
        public static var naturalLanguage: Syntax<String> { .init(get: { $0.value.asString }, set: { .init(.naturalLanguage($0)) }) }
        public static var mimeMediaType: Syntax<String> { .init(get: { $0.value.asString }, set: { .init(.mimeMediaType($0)) }) }
        public static var uri: Syntax<String> { .init(get: { $0.value.asString }, set: { .init(.uri($0)) }) }
        public static var uriScheme: Syntax<String> { .init(get: { $0.value.asString }, set: { .init(.uriScheme($0)) }) }
        public static var name: Syntax<String> { .init(get: { $0.value.asString }, set: { .init(.name(.withoutLanguage($0))) }) }
        public static var text: Syntax<String> { .init(get: { $0.value.asString }, set: { .init(.text(.withoutLanguage($0))) }) }

        public static func setOfKeywords<T: RawRepresentable<String>>(as: T.Type = T.self) -> Syntax<[T]> {
            .init(get: { $0.values.compactMap { $0.asString }.compactMap(T.init(rawValue:)) },
                  set: { v in .init(v.map(\.rawValue).map { .keyword($0) }) })
        }
    }

    // this is just here for to map key-paths to attributes in accessors
    static let attributes = Attributes()
}

public extension IppAttributes {
    /// Accesses the semantic attribute specified by the key path.
    ///
    /// If the IPP value cannot be converted to the specified type, `nil` is returned.
    /// Likewise, if the provided value cannot be converted to an IPP value, is removed from the attributes set.
    subscript<V>(_ attribute: KeyPath<SemanticModel.Attributes, SemanticModel.Attribute<V>>) -> V? {
        get {
            let key = SemanticModel.attributes[keyPath: attribute]
            return self[key.name].flatMap(key.syntax.get)
        }
        set {
            let key = SemanticModel.attributes[keyPath: attribute]
            self[key.name] = newValue.flatMap(key.syntax.set)
        }
    }

    /// Mutates this attribute dictionary in-place using the provided closure.
    mutating func with(_ mutation: (inout IppAttributes) -> Void) {
        mutation(&self)
    }
}

public extension IppAttribute.Value {
    /// Returns the value of this attribute as a string, if possible.
    var asString: String? {
        switch self {
        case let .charset(value),
             let .keyword(value),
             let .mimeMediaType(value),
             let .naturalLanguage(value),
             let .uri(value),
             let .uriScheme(value):
            value
        case let .text(value), let .name(value):
            value.string
        default:
            nil
        }
    }
}

extension IppAttribute.Value.TextOrName {
    /// Returns the text value of this attribute as a string (ie: ignoring the language if there is one)
    var string: String {
        switch self {
        case let .withoutLanguage(value):
            value
        case let .withLanguage(language: _, value):
            value
        }
    }
}

extension IppAttributeGroups: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (IppAttributeGroup.Name, IppAttributes)...) {
        self = elements.map { .init(name: $0.0, attributes: $0.1) }
    }
}
