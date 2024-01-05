import IppProtocol
import NIOCore
import XCTest

final class EncodingRoundTripTests: XCTestCase {
    func testMultipleAttributeGroups() throws {
        let request = IppRequest(
            version: .v1_1,
            operationId: .validateJob,
            requestId: 1,
            attributeGroups: [
                .operation: [
                    "attributes-charset": .init(.charset("utf-8")),
                    "attributes-natural-language": .init(.naturalLanguage("en-us")),
                ],
                .job: ["foo": .init(.boolean(false))],
                .printer: [:],
            ]
        )

        XCTAssertEqual(request, try request.roundtrippedCopy())
    }

    func testAttributesWithAdditionValues() throws {
        let request = IppRequest(
            version: .v1_1,
            operationId: .validateJob,
            requestId: 1,
            attributeGroups: [
                .operation: [
                    "some-list": .init(.integer(1), .integer(2), .integer(3)),
                ],
            ]
        )

        XCTAssertEqual(request, try request.roundtrippedCopy())
    }

    func testSimpleTypes() throws {
        let request = IppRequest(
            version: .v1_1,
            operationId: .validateJob,
            requestId: 999,
            attributeGroups: [
                .operation: [
                    "a": .init(.enumValue(1)),
                    "b": .init(.keyword("foo")),
                    "c": .init(.mimeMediaType("bar")),
                    "d": .init(.uri("ipp://yolo")),
                    "e": .init(.uriScheme("ipp")),
                    "f": .init(.boolean(true), .boolean(false)),
                    "oob": .init(.noValue, .unknown, .unsupported),
                ],
            ]
        )

        XCTAssertEqual(request, try request.roundtrippedCopy())
    }

    func testTextAndNameTypes() throws {
        let request = IppResponse(
            version: .v1_0,
            statusCode: .successfulOk,
            requestId: 999,
            attributeGroups: [
                .operation: [
                    "a": .init(.name(.withoutLanguage("foo")), .name(.withLanguage(language: "en", "bar"))),
                    "b": .init(.text(.withoutLanguage("baz")), .text(.withLanguage(language: "de", "baq"))),
                ],
            ]
        )

        XCTAssertEqual(request, try request.roundtrippedCopy())
    }

    func testComplexTypes() throws {
        let date = IppAttribute.Value.DateTime(year: 2024, month: 1, day: 2, hour: 3, minutes: 4, seconds: 5, deciSeconds: 6, directionFromUtc: UInt8(ascii: "-"), hoursFromUtc: 5, minutesFromUtc: 30)

        let request = IppResponse(
            version: .v1_0,
            statusCode: .successfulOk,
            requestId: 999,
            attributeGroups: [
                .operation: [
                    "a": .init(.dateTime(date)),
                    "b": .init(.resolution(.init(crossFeed: 10, feed: 20, units: 30))),
                    "c": .init(.rangeOfInteger(1 ... 5)),
                    "d": .init(.octetString([1, 2, 3, 4, 5])),
                ],
            ]
        )

        XCTAssertEqual(request, try request.roundtrippedCopy())
    }

    func testCollectionsWithLists() throws {
        let request = IppRequest(
            version: .v1_1,
            operationId: .validateJob,
            requestId: 1,
            attributeGroups: [
                .operation: [
                    "some-collection": .init(.collection(
                        [
                            "some-list": .init(.integer(1), .integer(2), .integer(3)),
                            "some-text": .init(.text(.withLanguage(language: "fr", "foo"))),
                        ]
                    )),
                ],
                .job: ["foo": .init(.collection([:]))],
            ]
        )

        XCTAssertEqual(request, try request.roundtrippedCopy())
    }

    func testNestedCollections() throws {
        let request = IppRequest(
            version: .v1_1,
            operationId: .validateJob,
            requestId: 1,
            attributeGroups: [
                .operation: [
                    "a": .init(.collection(
                        [
                            "b": .init(.collection(
                                [
                                    "foo": .init(.integer(1), .integer(2), .integer(3)),
                                ]
                            )),
                            "c": .init(.collection(
                                [
                                    "foo": .init(.boolean(true)),
                                ]
                            )),
                        ]
                    )),
                ]
            ]
        )

        XCTAssertEqual(request, try request.roundtrippedCopy())
    }

    func testUnsupportedGroupsAndValues() throws {
        let request = IppResponse(
            version: .v1_0,
            statusCode: .successfulOk,
            requestId: 999,
            attributeGroups: [
                .unknownGroup(tag: 0x0F): [
                    "a": .init(.unknownValueTag(tag: 0xFF, value: [1,2,3])),
                ],
            ]
        )

        XCTAssertEqual(request, try request.roundtrippedCopy())
    }

}

private extension IppRequest {
    func roundtrippedCopy() throws -> Self {
        var buffer = ByteBuffer()
        write(to: &buffer)
        return try Self(buffer: &buffer)
    }
}

private extension IppResponse {
    func roundtrippedCopy() throws -> Self {
        var buffer = ByteBuffer()
        write(to: &buffer)
        return try Self(buffer: &buffer)
    }
}
