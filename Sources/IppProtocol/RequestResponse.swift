import NIOCore
import OrderedCollections

/// Represents a request message that can be sent to an IPP object.
public struct IppRequest: Equatable, Sendable {
    public var version: IppVersion
    public var operationId: IppOperationId
    public var requestId: Int32
    public var attributeGroups: IppAttributeGroups

    public init(version: IppVersion, operationId: IppOperationId, requestId: Int32, attributeGroups: IppAttributeGroups) {
        self.version = version
        self.operationId = operationId
        self.requestId = requestId
        self.attributeGroups = attributeGroups
    }
}

/// Represents a response message that is returned by an IPP object.
public struct IppResponse: Equatable, Sendable {
    public var version: IppVersion
    public var statusCode: IppStatusCode
    public var requestId: Int32
    public var attributeGroups: IppAttributeGroups

    public init(version: IppVersion, statusCode: IppStatusCode, requestId: Int32, attributeGroups: IppAttributeGroups) {
        self.version = version
        self.statusCode = statusCode
        self.requestId = requestId
        self.attributeGroups = attributeGroups
    }
}

public struct IppVersion: Equatable, Sendable, CustomStringConvertible {
    public let major: Int8
    public let minor: Int8

    public init(major: Int8, minor: Int8) {
        self.major = major
        self.minor = minor
    }

    public var description: String {
        "\(major).\(minor)"
    }
}

public extension IppVersion {
    static var v1_0: Self { .init(major: 1, minor: 0) }
    static var v1_1: Self { .init(major: 1, minor: 1) }
}

public struct IppOperationId: RawRepresentable, Equatable, Sendable {
    public let rawValue: Int16

    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }

    public var description: String {
        "0x\(String(rawValue, radix: 16, uppercase: true))"
    }
}

public struct IppStatusCode: RawRepresentable, Equatable, Sendable, CustomStringConvertible {
    public let rawValue: Int16

    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }

    public var description: String {
        "0x\(String(rawValue, radix: 16, uppercase: true))"
    }
}

public struct IppAttributeGroup: Equatable, Sendable {
    public enum Name: Hashable, Sendable {
        case operation
        case job
        case printer
        case unsupported
        case unknownGroup(tag: UInt8)
    }

    public let name: Name
    public var attributes: IppAttributes

    public init(name: Name, attributes: IppAttributes) {
        self.name = name
        self.attributes = attributes
    }
}

public typealias IppAttributeGroups = [IppAttributeGroup]
public typealias IppAttributes = OrderedDictionary<IppAttribute.Name, IppAttribute>

public struct IppAttribute: Equatable, Sendable, CustomStringConvertible {
    internal var additionalValues: [Value]?

    /// The value of this attribute.
    /// If the attribute has multiple values, this will be the first value.
    public let value: Value

    public init(_ value: Value, _ additionalValues: Value...) {
        self.value = value

        if !additionalValues.isEmpty {
            self.additionalValues = additionalValues
        }
    }

    public init?(_ values: some Collection<Value>) {
        guard !values.isEmpty else { return nil }
        value = values.first!
        if values.count > 1 {
            additionalValues = Array(values.dropFirst())
        }
    }

    public var description: String {
        if isSet {
            "[\(values.map { "\($0)" }.joined(separator: ","))]"
        } else {
            "\(value)"
        }
    }
}

public extension IppAttribute {
    /// Returns `true` if this attribute has a list of values.
    var isSet: Bool {
        additionalValues != nil && additionalValues!.count > 0
    }

    /// Returns the list of values for this attribute.
    ///
    /// The list will always contain at least one value (equal to `value`)
    var values: [Value] {
        if let additionalValues = additionalValues {
            return [value] + additionalValues
        } else {
            return [value]
        }
    }
}

public extension IppAttribute {
    struct Name: RawRepresentable, Hashable, Sendable, CustomStringConvertible, ExpressibleByStringInterpolation {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }

        public var description: String {
            rawValue
        }
    }
}

public extension IppAttribute {
    enum Value: Equatable, Sendable {
        // out-of-band values
        case unknown
        case unsupported
        case noValue

        // possible values semantics
        case text(TextOrName)
        case name(TextOrName)

        case keyword(String)
        case enumValue(Int32)
        case uri(String)
        case uriScheme(String)
        case charset(String)
        case naturalLanguage(String)
        case mimeMediaType(String)

        case octetString([UInt8])
        case boolean(Bool)
        case integer(Int32)
        case rangeOfInteger(ClosedRange<Int32>)
        case dateTime(DateTime)
        case resolution(Resolution)

        case collection(IppAttributes)
        case unknownValueTag(tag: UInt8, value: [UInt8])
    }
}

public extension IppAttribute.Value {
    enum TextOrName: Equatable, Sendable, CustomStringConvertible {
        case withoutLanguage(String)
        case withLanguage(language: String, String)

        public var description: String {
            switch self {
            case let .withoutLanguage(value):
                return value
            case let .withLanguage(language, value):
                return "\(language):\(value)"
            }
        }
    }

    struct DateTime: Equatable, Sendable {
        public var year: Int16
        public var month: Int8
        public var day: Int8
        public var hour: Int8
        public var minutes: Int8
        public var seconds: Int8
        public var deciSeconds: Int8
        public var directionFromUtc: UInt8 // TODO: make this an enum
        public var hoursFromUtc: Int8
        public var minutesFromUtc: Int8

        public init(
            year: Int16,
            month: Int8,
            day: Int8,
            hour: Int8,
            minutes: Int8,
            seconds: Int8,
            deciSeconds: Int8,
            directionFromUtc: UInt8,
            hoursFromUtc: Int8,
            minutesFromUtc: Int8
        ) {
            self.year = year
            self.month = month
            self.day = day
            self.hour = hour
            self.minutes = minutes
            self.seconds = seconds
            self.deciSeconds = deciSeconds
            self.directionFromUtc = directionFromUtc
            self.hoursFromUtc = hoursFromUtc
            self.minutesFromUtc = minutesFromUtc
        }
    }

    struct Resolution: Equatable, Sendable {
        public var crossFeed: Int32
        public var feed: Int32
        public var units: Int8

        public init(crossFeed: Int32, feed: Int32, units: Int8) {
            self.crossFeed = crossFeed
            self.feed = feed
            self.units = units
        }
    }
}
