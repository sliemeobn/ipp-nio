import IppProtocol
import XCTest

final class AttributesTests: XCTestCase {
    func testInitalizesCorrectly() async throws {
        let request = IppRequest(printerUri: "ipp://some", operation: .cancelJob)
        XCTAssertEqual(request.version, .v1_1)
        XCTAssertEqual(request.operationId, .cancelJob)
        XCTAssertEqual(request[operation: \.attributesCharset], "utf-8")
        XCTAssertEqual(request[operation: \.attributesNaturalLanguage], "en")
        XCTAssertEqual(request[operation: \.printerUri], "ipp://some")

        XCTAssert(request[.operation].keys[0] == .attributesCharset)
        XCTAssert(request[.operation].keys[1] == .attributesNaturalLanguage)
        XCTAssert(request[.operation].keys[2] == .printerUri)
    }

    func testStringSemantics() {
        var attributes = IppAttributes()

        attributes[\.operation.attributesCharset] = "A"
        attributes[\.operation.attributesNaturalLanguage] = "B"
        attributes[\.operation.requestingUserName] = "C"
        attributes[\.operation.jobUri] = "D"

        XCTAssertEqual(attributes[.attributesCharset], .init(.charset("A")))
        XCTAssertEqual(attributes[.attributesNaturalLanguage], .init(.naturalLanguage("B")))
        XCTAssertEqual(attributes[.requestingUserName], .init(.name(.withoutLanguage("C"))))
        XCTAssertEqual(attributes[.jobUri], .init(.uri("D")))
        XCTAssertEqual(attributes[\.operation.attributesCharset], "A")
        XCTAssertEqual(attributes[\.operation.attributesNaturalLanguage], "B")
        XCTAssertEqual(attributes[\.operation.requestingUserName], "C")
        XCTAssertEqual(attributes[\.operation.jobUri], "D")
    }

    func testSetOfKeywordsSemantics() {
        var attributes = IppAttributes()

        attributes[\.operation.requestedAttributes] = ["A", "B"]

        XCTAssertEqual(attributes[.requestedAttributes]?.values, [.keyword("A"), .keyword("B")])
        XCTAssertEqual(attributes[\.operation.requestedAttributes], ["A", "B"])
    }

    func testEnumSemantics() {
        var attributes = IppAttributes()

        attributes[\.jobTemplate.orientationRequested] = .portrait

        XCTAssertEqual(attributes[.orientationRequested], .init(.enumValue(3)))
        XCTAssertEqual(attributes[\.jobTemplate.orientationRequested], .portrait)
    }
}
