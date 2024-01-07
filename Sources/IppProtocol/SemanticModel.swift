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
        public let operation = Operation()
        public let operationResponse = OperationResponse()
        public let jobTemplate = JobTemplate()
        public let jobDescription = JobDescription()
        public let printerDescription = PrinterDescription()

        public struct Operation {
            public var attributesCharset: Attribute<String> { .init(name: .attributesCharset, syntax: Syntaxes.charset) }
            public var attributesNaturalLanguage: Attribute<String> { .init(name: .attributesNaturalLanguage, syntax: Syntaxes.naturalLanguage) }
            public var printerUri: Attribute<String> { .init(name: .printerUri, syntax: Syntaxes.uri) }
            public var jobUri: Attribute<String> { .init(name: .jobUri, syntax: Syntaxes.uri) }
            public var jobId: Attribute<Int32> { .init(name: .jobId, syntax: Syntaxes.integer) }
            public var documentUri: Attribute<String> { .init(name: .documentUri, syntax: Syntaxes.uri) }
            public var requestingUserName: Attribute<String> { .init(name: .requestingUserName, syntax: Syntaxes.name) }
            public var jobName: Attribute<String> { .init(name: .jobName, syntax: Syntaxes.name) }
            public var documentName: Attribute<String> { .init(name: .documentName, syntax: Syntaxes.name) }
            public var requestedAttributes: Attribute<[IppAttribute.Name]> { .init(name: .requestedAttributes, syntax: Syntaxes.setOf(Syntaxes.keyword())) }
            public var documentFormat: Attribute<String> { .init(name: .documentFormat, syntax: Syntaxes.mimeMediaType) }
            public var ippAttributeFidelity: Attribute<Bool> { .init(name: .ippAttributeFidelity, syntax: Syntaxes.boolean) }
        }

        public struct OperationResponse {
            public var attributesCharset: Attribute<String> { .init(name: .attributesCharset, syntax: Syntaxes.charset) }
            public var attributesNaturalLanguage: Attribute<String> { .init(name: .attributesNaturalLanguage, syntax: Syntaxes.naturalLanguage) }
            public var statusMessage: Attribute<String> { .init(name: .statusMessage, syntax: Syntaxes.text) }
            public var detailedStatusMessage: Attribute<String> { .init(name: .detailedStatusMessage, syntax: Syntaxes.text) }
        }

        public struct JobTemplate {
            public var copies: Attribute<Int32> { .init(name: .copies, syntax: Syntaxes.integer) }
            public var orientationRequested: Attribute<Orientation> { .init(name: .orientationRequested, syntax: Syntaxes.enum()) }
            public var printQuality: Attribute<PrintQuality> { .init(name: .printQuality, syntax: Syntaxes.enum()) }
            public var sides: Attribute<Sides> { .init(name: .sides, syntax: Syntaxes.keyword()) }
        }

        public struct JobDescription {
            public var jobUri: Attribute<String> { .init(name: .jobUri, syntax: Syntaxes.uri) }
            public var jobId: Attribute<Int32> { .init(name: .jobId, syntax: Syntaxes.integer) }
            public var jobState: Attribute<JobState> { .init(name: .jobState, syntax: Syntaxes.enum()) }
        }

        public struct PrinterDescription {
            public var printerName: Attribute<String> { .init(name: .printerName, syntax: Syntaxes.name) }
            public var printerLocation: Attribute<String> { .init(name: .printerLocation, syntax: Syntaxes.text) }
            public var printerInfo: Attribute<String> { .init(name: .printerInfo, syntax: Syntaxes.text) }
            public var printerState: Attribute<PrinterState> { .init(name: .printerState, syntax: Syntaxes.enum()) }
            public var printerStateReasons: Attribute<[PrinterStateReason]> { .init(name: .printerStateReasons, syntax: Syntaxes.setOf(Syntaxes.keyword())) }
            public var printerIsAcceptingJobs: Attribute<Bool> { .init(name: .printerIsAcceptingJobs, syntax: Syntaxes.boolean) }
            public var queuedJobCount: Attribute<Int32> { .init(name: .queuedJobCount, syntax: Syntaxes.integer) }
            public var printerMessageFromOperator: Attribute<String> { .init(name: .printerMessageFromOperator, syntax: Syntaxes.text) }
            public var colorSupported: Attribute<Bool> { .init(name: .colorSupported, syntax: Syntaxes.boolean) }
        }
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
        public static var integer: Syntax<Int32> { .init(get: { $0.value.asInteger }, set: { .init(.integer($0)) }) }
        public static var boolean: Syntax<Bool> { .init(get: { $0.value.asBool }, set: { .init(.boolean($0)) }) }

        // keyword
        public static func keyword<T: RawRepresentable<String>>(as: T.Type = T.self) -> Syntax<T> {
            .init(get: { $0.value.asString.flatMap(T.init(rawValue:)) },
                  set: { .init(.keyword($0.rawValue)) })
        }

        public static func `enum`<T: RawRepresentable<Int32>>(as: T.Type = T.self) -> Syntax<T> {
            .init(get: { $0.value.asInteger.flatMap(T.init(rawValue:)) },
                  set: { .init(.enumValue($0.rawValue)) })
        }

        public static func setOf<T>(_ syntax: Syntax<T>) -> Syntax<[T]> {
            .init(get: { $0.values.map { IppAttribute($0) }.compactMap(syntax.get) },
                  set: { v in .init(v.compactMap(syntax.set).reduce(into: []) { $0.append($1.value) }) })
        }
    }

    // this is just here for to map key-paths to attributes in accessors
    static let attributes = Attributes()
}

public extension SemanticModel {
    enum Orientation: Int32 {
        case portrait = 3
        case landscape = 4
        case reverseLandscape = 5
        case reversePortrait = 6
    }

    enum PrintQuality: Int32 {
        case draft = 3
        case normal = 4
        case high = 5
    }

    struct Sides: RawRepresentable, CustomStringConvertible {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static var oneSided: Self { Self(rawValue: "one-sided") }
        public static var twoSidedLongEdge: Self { Self(rawValue: "two-sided-long-edge") }
        public static var twoSidedShortEdge: Self { Self(rawValue: "two-sided-short-edge") }

        public var description: String { rawValue }
    }

    enum JobState: Int32 {
        case pending = 3
        case pendingHeld = 4
        case processing = 5
        case processingStopped = 6
        case canceled = 7
        case aborted = 8
        case completed = 9
    }

    enum PrinterState: Int32 {
        case idle = 3
        case processing = 4
        case stopped = 5
    }

    struct PrinterStateReason: RawRepresentable, CustomStringConvertible {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static var other: Self { Self(rawValue: "other") }
        public static var mediaNeeded: Self { Self(rawValue: "media-needed") }
        public static var mediaJam: Self { Self(rawValue: "media-jam") }
        public static var movingToPaused: Self { Self(rawValue: "moving-to-paused") }
        public static var paused: Self { Self(rawValue: "paused") }
        public static var shutdown: Self { Self(rawValue: "shutdown") }
        public static var connectingToDevice: Self { Self(rawValue: "connecting-to-device") }
        public static var timedOut: Self { Self(rawValue: "timed-out") }
        public static var stopping: Self { Self(rawValue: "stopping") }
        public static var stoppedPartly: Self { Self(rawValue: "stopped-partly") }
        public static var tonerLow: Self { Self(rawValue: "toner-low") }
        public static var tonerEmpty: Self { Self(rawValue: "toner-empty") }
        public static var spoolAreaFull: Self { Self(rawValue: "spool-area-full") }
        public static var coverOpen: Self { Self(rawValue: "cover-open") }
        public static var interlockOpen: Self { Self(rawValue: "interlock-open") }
        public static var doorOpen: Self { Self(rawValue: "door-open") }
        public static var inputTrayMissing: Self { Self(rawValue: "input-tray-missing") }
        public static var mediaLow: Self { Self(rawValue: "media-low") }
        public static var mediaEmpty: Self { Self(rawValue: "media-empty") }
        public static var outputTrayMissing: Self { Self(rawValue: "output-tray-missing") }
        public static var outputAreaAlmostFull: Self { Self(rawValue: "output-area-almost-full") }
        public static var outputAreaFull: Self { Self(rawValue: "output-area-full") }
        public static var markerSupplyLow: Self { Self(rawValue: "marker-supply-low") }
        public static var markerSupplyEmpty: Self { Self(rawValue: "marker-supply-empty") }
        public static var markerWasteAlmostFull: Self { Self(rawValue: "marker-waste-almost-full") }

        public var description: String { rawValue }
    }
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

    var asInteger: Int32? {
        switch self {
        case let .integer(value): value
        case let .enumValue(value): value
        default:
            nil
        }
    }

    var asBool: Bool? {
        switch self {
        case let .boolean(value): value
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
