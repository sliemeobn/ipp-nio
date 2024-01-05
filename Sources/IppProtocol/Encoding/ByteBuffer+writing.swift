import NIOCore

extension ByteBuffer {
    mutating func writeIppCodable(_ codable: some IppCodable) {
        writeVersion(codable.version)
        writeMultipleIntegers(codable.operationIdOrStatusCode, codable.requestId)
        writeAttributeGroups(codable.attributeGroups)
        writeInteger(DelimiterTag.endOfAttributes.rawValue)
    }

    mutating func writeVersion(_ version: IppVersion) {
        writeMultipleIntegers(version.major, version.minor)
    }

    mutating func writeAttributeGroups(_ groups: IppAttributeGroups) {
        for (group) in groups {
            writeInteger(group.name.tag)

            for (name, attribute) in group.attributes.elements {
                writeAttribute(attribute, named: name.rawValue)
            }
        }
    }

    mutating func writeAttribute(_ attribute: IppAttribute, named name: String?) {
        writeAttributeValue(attribute.value, withName: name)
        if let additionalValues = attribute.additionalValues {
            for value in additionalValues {
                writeAttributeValue(value, withName: nil)
            }
        }
    }

    mutating func writeAttributeValue(_ value: IppAttribute.Value, withName name: String?) {
        func writeValuePrelude(_ tag: ValueTag) {
            writeValuePrelude(tag.rawValue)
        }

        func writeValuePrelude(_ tag: ValueTag.RawValue) {
            writeInteger(tag)

            if let name {
                writeStringWithSize(name)
            } else {
                writeInteger(.zeroLength)
            }
        }

        switch value {
        // numbers and bool
        case let .integer(value):
            writeValuePrelude(.integer)
            writeMultipleIntegers(Int16(4), value)
        case let .boolean(value):
            writeValuePrelude(.boolean)
            writeMultipleIntegers(Int16(1), Int8(value ? 1 : 0))
        case let .enumValue(value):
            writeValuePrelude(.enum)
            writeMultipleIntegers(Int16(4), value)

        // all string values
        case let .charset(value):
            writeValuePrelude(.charset)
            writeStringWithSize(value)
        case let .keyword(value):
            writeValuePrelude(.keyword)
            writeStringWithSize(value)
        case let .mimeMediaType(value):
            writeValuePrelude(.mimeMediaType)
            writeStringWithSize(value)
        case let .name(.withoutLanguage(value)):
            writeValuePrelude(.nameWithoutLanguage)
            writeStringWithSize(value)
        case let .text(.withoutLanguage(value)):
            writeValuePrelude(.textWithoutLanguage)
            writeStringWithSize(value)
        case let .naturalLanguage(value):
            writeValuePrelude(.naturalLanguage)
            writeStringWithSize(value)
        case let .uri(value):
            writeValuePrelude(.uri)
            writeStringWithSize(value)
        case let .uriScheme(value):
            writeValuePrelude(.uriScheme)
            writeStringWithSize(value)

        // plain text versions are matched above, these are with language
        case let .name(withLanguage):
            writeValuePrelude(.nameWithLanguage)
            writeStringWithSize(withLanguage)
        case let .text(withLanguage):
            writeValuePrelude(.textWithLanguage)
            writeStringWithSize(withLanguage)

        // complex values
        case let .dateTime(value):
            writeValuePrelude(.dateTime)
            writeMultipleIntegers(
                Int16(11),
                value.year, value.month, value.day,
                value.hour, value.minutes, value.seconds, value.deciSeconds,
                value.directionFromUtc, value.hoursFromUtc, value.minutesFromUtc
            )
        case let .resolution(value):
            writeValuePrelude(.resolution)
            writeMultipleIntegers(Int16(9), value.crossFeed, value.feed, value.units)
        case let .rangeOfInteger(value):
            writeValuePrelude(.rangeOfInteger)
            writeMultipleIntegers(Int16(8), value.lowerBound, value.upperBound)
        case let .octetString(value):
            writeValuePrelude(.octetString)
            writeInteger(Int16(value.count))
            writeBytes(value)

        // out-of-band values
        case .unsupported:
            writeValuePrelude(.unsupported)
            writeInteger(.zeroLength)
        case .unknown:
            writeValuePrelude(.unknown)
            writeInteger(.zeroLength)
        case .noValue:
            writeValuePrelude(.noValue)
            writeInteger(.zeroLength)

        // collection
        case let .collection(collection):
            writeValuePrelude(.begCollection)
            writeInteger(.zeroLength) // value length

            for (name, member) in collection {
                writeValue(ValueTag.memberAttrName)
                writeInteger(.zeroLength) // name length
                writeStringWithSize(name.rawValue) // name as value
                // write all values without a leading name
                writeAttribute(member, named: nil)
            }

            writeMultipleIntegers(
                ValueTag.endCollection.rawValue,
                .zeroLength, // name length
                .zeroLength // value length
            )
        case let .unknownValueTag(tag, value):
            writeValuePrelude(tag)
            writeInteger(Int16(value.count))
            writeBytes(value)
        }
    }
}

// value helpers
extension ByteBuffer {
    mutating func writeStringWithSize(_ value: IppAttribute.Value.TextOrName) {
        switch value {
        case let .withoutLanguage(text):
            writeStringWithSize(text)
        case let .withLanguage(language, text):
            writeInteger(Int16(4 + language.count + text.count))
            writeStringWithSize(language)
            writeStringWithSize(text)
        }
    }

    mutating func writeStringWithSize(_ value: String) {
        writeInteger(Int16(value.utf8.count))
        writeString(value)
    }

    mutating func writeValue<T>(_ value: some RawRepresentable<T>) where T: FixedWidthInteger {
        writeInteger(value.rawValue)
    }
}
