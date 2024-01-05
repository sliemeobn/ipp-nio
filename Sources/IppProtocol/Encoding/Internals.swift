enum DelimiterTag: UInt8 {
    case operationAttributes = 0x01
    case jobAttributes = 0x02
    case endOfAttributes = 0x03
    case printerAttributes = 0x04
    case unsupportedAttributes = 0x05

    static var valueRange: ClosedRange<UInt8> { 0x00 ... 0x0F }
}

enum ValueTag: UInt8 {
    case unsupported = 0x10
    case unknown = 0x12
    case noValue = 0x13

    case integer = 0x21
    case boolean = 0x22
    case `enum` = 0x23
    case octetString = 0x30
    case dateTime = 0x31
    case resolution = 0x32
    case rangeOfInteger = 0x33
    case begCollection = 0x34
    case textWithLanguage = 0x35
    case nameWithLanguage = 0x36
    case endCollection = 0x37
    case textWithoutLanguage = 0x41
    case nameWithoutLanguage = 0x42
    case keyword = 0x44
    case uri = 0x45
    case uriScheme = 0x46
    case charset = 0x47
    case naturalLanguage = 0x48
    case mimeMediaType = 0x49
    case memberAttrName = 0x4A

    static var valueRange: ClosedRange<UInt8> { 0x10 ... 0xFF }
}

extension IppAttributeGroup.Name {
    var tag: UInt8 {
        return switch self {
        case .operation:
            DelimiterTag.operationAttributes.rawValue
        case .job:
            DelimiterTag.jobAttributes.rawValue
        case .printer:
            DelimiterTag.printerAttributes.rawValue
        case .unsupported:
            DelimiterTag.unsupportedAttributes.rawValue
        case let .unknownGroup(tag):
            tag
        }
    }

    init(tag: UInt8) {
        guard let delimiterTag = DelimiterTag(rawValue: tag) else {
            self = .unknownGroup(tag: tag)
            return
        }

        self = switch delimiterTag {
        case .operationAttributes: .operation
        case .jobAttributes: .job
        case .printerAttributes: .printer
        case .unsupportedAttributes: .unsupported
        case .endOfAttributes: preconditionFailure("endOfAttributes is not a valid group name")
        }
    }
}

extension FixedWidthInteger where Self == Int16 {
    static var zeroLength: Self { 0 }
}

/// Internal protocol for serializing and deserializing IPP requests and responses.
protocol IppCodable {
    var version: IppVersion { get }
    var operationIdOrStatusCode: Int16 { get }
    var requestId: Int32 { get }
    var attributeGroups: IppAttributeGroups { get }

    init(
        version: IppVersion,
        operationIdOrStatusCode: Int16,
        requestId: Int32,
        attributeGroups: IppAttributeGroups
    )
}

extension IppRequest: IppCodable {
    var operationIdOrStatusCode: Int16 { operationId.rawValue }
    init(version: IppVersion, operationIdOrStatusCode: Int16, requestId: Int32, attributeGroups: IppAttributeGroups) {
        self.init(
            version: version,
            operationId: IppOperationId(rawValue: operationIdOrStatusCode),
            requestId: requestId,
            attributeGroups: attributeGroups
        )
    }
}

extension IppResponse: IppCodable {
    var operationIdOrStatusCode: Int16 { statusCode.rawValue }
    init(version: IppVersion, operationIdOrStatusCode: Int16, requestId: Int32, attributeGroups: IppAttributeGroups) {
        self.init(
            version: version,
            statusCode: IppStatusCode(rawValue: operationIdOrStatusCode),
            requestId: requestId,
            attributeGroups: attributeGroups
        )
    }
}
