import struct Foundation.URLComponents

/// Defines an IPP object that can be used to create and execute IPP requests.
///
/// This is to decouple the specific HTTP transport from the semantic mode.
public protocol IppObjectProtocol {
    associatedtype DataFormat
    func makeNewRequest(operation: IppOperationId) -> IppRequest
    func execute(request: IppRequest, data: DataFormat?) async throws -> IppResponse
}

public protocol IppPrinterObject: IppObjectProtocol {}
// could be extended to support other IPP objects like jobs, etc. with their own API

public extension IppPrinterObject {
    /// Executes a Get-Printer-Attributes request.
    func getPrinterAttributes(
        requestedAttributes: [IppAttribute.Name]? = nil,
        documentFormat: String? = nil
    ) async throws -> IppResponse {
        var request = makeNewRequest(operation: .getPrinterAttributes)

        request[.operation].with {
            $0[\.operation.requestedAttributes] = requestedAttributes
            $0[\.operation.documentFormat] = documentFormat
        }

        print(request)

        return try await execute(request: request, data: nil)
    }

    func printJob(
        jobName: String? = nil,
        documentName: String? = nil,
        documentFormat: String? = nil,
        jobAttributes: IppAttributes = [:],
        data: DataFormat) async throws -> IppResponse {
        var request = makeNewRequest(operation: .printJob)

        request[.operation].with {
            $0[\.operation.jobName] = jobName
            $0[\.operation.documentName] = documentName
            $0[\.operation.documentFormat] = documentFormat
        }

        request[.job] = jobAttributes

        print(request)

        return try await execute(request: request, data: data)
    }
}

public extension IppRequest {
    /// Creates a new IPP request with the given printer URI, operation ID, and attributes natural language.
    init(printerUri: String, operation: IppOperationId, attributesNaturalLanguage: String = "en", version: IppVersion = .v1_1) {
        self.init(version: .v1_1, operationId: operation, requestId: 1, attributeGroups: [])

        self[.operation].with {
            $0[\.operation.attributesCharset] = "utf-8"
            $0[\.operation.attributesNaturalLanguage] = attributesNaturalLanguage
            $0[\.operation.printerUri] = printerUri
        }
    }

    package func getTargetUriIfValidOrThrow() throws -> String {
        guard let firstGroup = attributeGroups.first,
              firstGroup.name == .operation,
              firstGroup.attributes.count >= 3
        else {
            throw IppParsingError.fooBar
        }

        guard firstGroup.attributes.keys[0] == .attributesCharset,
              firstGroup.attributes.keys[1] == .attributesNaturalLanguage,
              firstGroup.attributes.keys[2] == .printerUri || firstGroup.attributes.keys[2] == .jobUri,
              case let .uri(uri) = firstGroup.attributes.values[2].value
        else {
            throw IppParsingError.fooBar
        }

        guard var targetURL = URLComponents(string: uri) else {
            throw IppParsingError.fooBar
        }

        switch targetURL.scheme {
        case "ipp":
            targetURL.scheme = "http"
        case "ipps":
            targetURL.scheme = "https"
        default:
            throw IppParsingError.fooBar
        }

        targetURL.port = targetURL.port ?? 631
        return targetURL.string!
    }
}