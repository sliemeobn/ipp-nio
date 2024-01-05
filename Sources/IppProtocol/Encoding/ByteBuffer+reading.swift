import NIOCore

extension ByteBuffer {
    mutating func readIppCodable<S: IppCodable>(as: S.Type = S.self) throws -> S {
        let version = try readVersion()

        guard let (operationIdOrStatusCode, requestId) = readMultipleIntegers(as: (Int16, Int32).self) else {
            throw ParsingError.malformedHeader
        }

        let attributeGroups = try readAttributeGroups()

        return S(
            version: version,
            operationIdOrStatusCode: operationIdOrStatusCode,
            requestId: requestId,
            attributeGroups: attributeGroups
        )
    }

    mutating func readVersion() throws -> IppVersion {
        guard let (major, minor) = readMultipleIntegers(as: (Int8, Int8).self) else {
            throw ParsingError.malformedHeader
        }

        return IppVersion(major: major, minor: minor)
    }

    mutating func readAttributeGroups() throws -> IppAttributeGroups {
        var groups: IppAttributeGroups = []

        while let tag = readInteger(as: UInt8.self) {
            guard DelimiterTag.valueRange.contains(tag) else {
                throw ParsingError.unexpectedValueTag(tag)
            }

            if tag == DelimiterTag.endOfAttributes.rawValue {
                return groups
            }

            let name = IppAttributeGroup.Name(tag: tag)
            let attributes = try readGroupAttributes()
            groups.append(.init(name: name, attributes: attributes))
        }

        throw ParsingError.missingEndOfAttributes
    }

    mutating func readGroupAttributes() throws -> IppAttributes {
        var group: IppAttributes = [:]

        while let (tag, name, valueSlice) = try readNextValueTriple() {
            var value: IppAttribute.Value

            switch tag {
            case ValueTag.begCollection.rawValue:
                value = try readAttributeCollection()
            case ValueTag.endCollection.rawValue, ValueTag.memberAttrName.rawValue:
                throw ParsingError.unexpectedValueTag(tag)
            default:
                value = try IppAttribute.Value(tag: tag, valueSlice: valueSlice)
            }

            try group.pushValue(value, withName: name)
        }

        return group
    }

    mutating func readAttributeCollection() throws -> IppAttribute.Value {
        var collection: IppAttributes = [:]

        var currentName: String? = nil

        while let (tag, name, valueSlice) = try readNextValueTriple() {
            guard name == nil else {
                throw ParsingError.invalidCollectionSyntax(name!)
            }

            var value: IppAttribute.Value

            switch tag {
            case ValueTag.memberAttrName.rawValue:
                let newName = String(buffer: valueSlice)

                guard currentName == nil else {
                    throw ParsingError.invalidCollectionSyntax(newName)
                }

                currentName = newName
                continue
            case ValueTag.begCollection.rawValue:
                value = try readAttributeCollection()
            case ValueTag.endCollection.rawValue:
                guard currentName == nil else {
                    throw ParsingError.invalidCollectionSyntax(currentName!)
                }
                return .collection(collection)
            default:
                value = try IppAttribute.Value(tag: tag, valueSlice: valueSlice)
            }

            try collection.pushValue(value, withName: currentName)
            currentName = nil
        }

        throw ParsingError.missingEndOfCollection
    }

    mutating func readNextValueTriple() throws -> (UInt8, String?, ByteBuffer)? {
        guard let tag = getInteger(at: readerIndex, as: UInt8.self) else {
            throw ParsingError.malformedValue
        }

        guard ValueTag.valueRange.contains(tag) else {
            // next tag is delimiter do not read further
            return nil
        }

        moveReaderIndex(forwardBy: 1)

        let name = try readSizedString()
        let valueSlice = try readValueSlice()
        return (tag, name, valueSlice)
    }

    mutating func readSizedString() throws -> String? {
        guard let length = readInteger(as: Int16.self) else { throw ParsingError.malformedValue }
        guard length != .zeroLength else { return nil }
        guard let string = readString(length: Int(length)) else { throw ParsingError.malformedValue }
        return string
    }

    mutating func readStringWithLanguage() throws -> IppAttribute.Value.TextOrName {
        let language = try readSizedString()
        let string = try readSizedString()
        return .withLanguage(language: language ?? "", string ?? "")
    }

    mutating func readValueSlice() throws -> ByteBuffer {
        guard let length = readInteger(as: Int16.self) else { throw ParsingError.malformedValue }
        guard let slice = readSlice(length: Int(length)) else { throw ParsingError.malformedValue }
        return slice
    }
}

extension ByteBuffer {
    mutating func readValue<R, I>(as type: R.Type) -> R?
        where R: RawRepresentable<I>, I: FixedWidthInteger
    {
        guard let rawValue = readInteger(as: I.self) else { return nil }
        return R(rawValue: rawValue)
    }

    consuming func readToEndOrFail<T>(_ readFn: (inout Self) throws -> T?) throws -> T {
        guard let value = try readFn(&self) else {
            throw ParsingError.malformedValue
        }

        guard readableBytes == 0 else {
            throw ParsingError.malformedValue
        }

        return value
    }
}

extension IppAttribute.Value {
    init(tag: UInt8, valueSlice: consuming ByteBuffer) throws {
        guard let valueTag = ValueTag(rawValue: tag) else {
            self = .unknownValueTag(
                tag: tag,
                value: Array(buffer: valueSlice)
            )
            return
        }

        switch valueTag {
        // numbers and bool
        case .integer:
            let value = try valueSlice.readToEndOrFail {
                $0.readInteger(as: Int32.self)
            }

            self = .integer(value)
        case .boolean:
            let value = try valueSlice.readToEndOrFail {
                $0.readInteger(as: UInt8.self)
            }

            self = .boolean(value != 0)
        case .enum:
            let value = try valueSlice.readToEndOrFail {
                $0.readInteger(as: Int32.self)
            }

            self = .enumValue(value)

        // all string values
        case .charset:
            self = .charset(String(buffer: valueSlice))
        case .keyword:
            self = .keyword(String(buffer: valueSlice))
        case .mimeMediaType:
            self = .mimeMediaType(String(buffer: valueSlice))
        case .nameWithoutLanguage:
            self = .name(.withoutLanguage(String(buffer: valueSlice)))
        case .textWithoutLanguage:
            self = .text(.withoutLanguage(String(buffer: valueSlice)))
        case .naturalLanguage:
            self = .naturalLanguage(String(buffer: valueSlice))
        case .uri:
            self = .uri(String(buffer: valueSlice))
        case .uriScheme:
            self = .uriScheme(String(buffer: valueSlice))

        // strings with language
        case .nameWithLanguage:
            let value = try valueSlice.readToEndOrFail {
                try $0.readStringWithLanguage()
            }
            self = .name(value)
        case .textWithLanguage:
            let value = try valueSlice.readToEndOrFail {
                try $0.readStringWithLanguage()
            }
            self = .text(value)

        // complex values
        case .dateTime:
            let (year, month, day, hour, minutes, seconds, deciSeconds, directionFromUtc, hoursFromUtc, minutesFromUtc) = try valueSlice.readToEndOrFail {
                $0.readMultipleIntegers(as: (Int16, Int8, Int8, Int8, Int8, Int8, Int8, UInt8, Int8, Int8).self)
            }

            self = .dateTime(DateTime(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minutes: minutes,
                seconds: seconds,
                deciSeconds: deciSeconds,
                directionFromUtc: directionFromUtc,
                hoursFromUtc: hoursFromUtc,
                minutesFromUtc: minutesFromUtc
            ))
        case .resolution:
            let (crossFeed, feed, units) = try valueSlice.readToEndOrFail {
                $0.readMultipleIntegers(as: (Int32, Int32, Int8).self)
            }

            self = .resolution(Resolution(
                crossFeed: crossFeed,
                feed: feed,
                units: units
            ))
        case .rangeOfInteger:
            let (lower, upper) = try valueSlice.readToEndOrFail {
                $0.readMultipleIntegers(as: (Int32, Int32).self)
            }

            self = .rangeOfInteger(lower ... upper)
        case .octetString:
            self = .octetString(Array(buffer: valueSlice))

        // out-of-band values
        case .unsupported:
            self = .unsupported
        case .unknown:
            self = .unknown
        case .noValue:
            self = .noValue

        case .begCollection, .endCollection, .memberAttrName:
            preconditionFailure("Collection tags cannot be turned into values")
        }
    }
}

private extension IppAttributes {
    mutating func pushValue(_ value: consuming IppAttribute.Value, withName name: consuming String?) throws {
        if let name {
            // push next attribute to group
            self[IppAttribute.Name(rawValue: name)] = IppAttribute(value)
        } else {
            // push value as additional to last value
            guard !isEmpty else {
                throw ParsingError.malformedValue
            }
            let lastIndex = values.endIndex - 1
            values[lastIndex].pushAdditionalValue(value)
        }
    }
}

private extension IppAttribute {
    mutating func pushAdditionalValue(_ value: Value) {
        if additionalValues == nil {
            additionalValues = [value]
        } else {
            additionalValues!.append(value)
        }
    }
}

internal enum ParsingError: Error, CustomStringConvertible {
    case malformedHeader
    case unexpectedValueTag(UInt8)
    case unexpectedDelimiterTag(UInt8)
    case missingEndOfAttributes
    case missingEndOfCollection
    case invalidCollectionSyntax(String)
    case malformedValue

    var description: String {
        switch self {
        case .malformedHeader:
            "Malformed header. Could not read mandatory IPP version, operation or status code, and request ID."
        case let .unexpectedValueTag(tag):
            "Unexpected value tag \(tag)."
        case let .unexpectedDelimiterTag(tag):
            "Unexpected delimiter tag \(tag)."
        case .missingEndOfAttributes:
            "Missing end of attributes delimiter."
        case .missingEndOfCollection:
            "Missing end of collection delimiter."
        case let .invalidCollectionSyntax(name):
            "Invalid collection syntax. Unexpected name \(name)."
        case .malformedValue:
            "Malformed value."
        }
    }
}
