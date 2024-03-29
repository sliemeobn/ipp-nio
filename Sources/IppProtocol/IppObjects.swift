import struct Foundation.URLComponents // NOTE: the only use of Foundation... worth it?

/// Defines an IPP object that can be used to create and execute IPP requests.
///
/// This is to decouple the specific HTTP transport from the semantic mode.
public protocol IppObjectProtocol {
    associatedtype DataFormat
    /// Creates a new IPP request with the given operation ID that is targeted at this object.
    ///
    /// The request will be initialized with the IPP version, operation ID, the the required attributes for its target.
    func makeNewRequest(operation: IppOperationId) -> IppRequest

    /// Executes the given request and returns the response.
    func execute(request: IppRequest, data: DataFormat?) async throws -> IppResponse
}

/// Defines a simplified API for the most common operations of IPP printers.
public protocol IppPrinterObject: IppObjectProtocol {}

/// Defines a simplified API for the most common operations of IPP jobs.
public protocol IppJobObject: IppObjectProtocol {}

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

        return try await execute(request: request, data: nil)
    }

    /// Executes a Print-Job request.
    func printJob(
        jobName: String? = nil,
        attributeFidelity: Bool? = nil,
        documentName: String? = nil,
        documentFormat: String? = nil,
        jobAttributes: IppAttributes? = nil,
        data: DataFormat
    ) async throws -> IppResponse {
        var request = makeNewRequest(operation: .printJob)

        request[.operation].with {
            $0[\.operation.jobName] = jobName
            $0[\.operation.ippAttributeFidelity] = attributeFidelity
            $0[\.operation.documentName] = documentName
            $0[\.operation.documentFormat] = documentFormat
        }

        if let jobAttributes = jobAttributes {
            request[.job] = jobAttributes
        }

        return try await execute(request: request, data: data)
    }
}

public extension IppJobObject {
    /// Executes a Get-Job-Attributes request.
    func getJobAttributes(
        requestedAttributes: [IppAttribute.Name]? = nil
    ) async throws -> IppResponse {
        var request = makeNewRequest(operation: .getJobAttributes)

        request[operation: \.requestedAttributes] = requestedAttributes

        return try await execute(request: request, data: nil)
    }

    /// Execute a Cancel-Job request.
    func cancelJob(message: String? = nil) async throws -> IppResponse {
        var request = makeNewRequest(operation: .cancelJob)

        request[operation: \.message] = message

        return try await execute(request: request, data: nil)
    }
}

public extension IppRequest {
    /// Creates a new IPP request targetet at a printer object.
    init(
        printerUri: String,
        operation: IppOperationId,
        requestingUserName: String? = nil,
        attributesNaturalLanguage: String = "en",
        version: IppVersion = .v1_1
    ) {
        // NOTE: maybe use a running number for requestId? not really worth the complexity though (nobody cares about it)
        self.init(version: .v1_1, operationId: operation, requestId: 1)

        // the order of these is important
        self[.operation].with {
            $0[\.operation.attributesCharset] = "utf-8"
            $0[\.operation.attributesNaturalLanguage] = attributesNaturalLanguage
            $0[\.operation.printerUri] = printerUri
            $0[\.operation.requestingUserName] = requestingUserName
        }
    }

    /// Creates a new IPP request targeted at a job object.
    init(
        printerUri: String,
        jobId: Int32,
        operation: IppOperationId,
        requestingUserName: String? = nil,
        attributesNaturalLanguage: String = "en",
        version: IppVersion = .v1_1
    ) {
        self.init(version: .v1_1, operationId: operation, requestId: 1)

        // the order of these is important
        self[.operation].with {
            $0[\.operation.attributesCharset] = "utf-8"
            $0[\.operation.attributesNaturalLanguage] = attributesNaturalLanguage
            $0[\.operation.printerUri] = printerUri
            $0[\.operation.jobId] = jobId
            $0[\.operation.requestingUserName] = requestingUserName
        }
    }

    /// Returns the target URL for this request or throws if the request is invalid.
    ///
    /// Accessing this propery will throw if the request does not contain the required attributes for sending
    /// according to the IPP specification.
    var validatedHttpTargetUrl: String {
        get throws {
            guard let firstGroup = attributeGroups.first,
                  firstGroup.name == .operation,
                  firstGroup.attributes.count >= 3
            else {
                throw InvalidRequestError.invalidOperationAttributes
            }

            guard firstGroup.attributes.keys[0] == .attributesCharset,
                  firstGroup.attributes.keys[1] == .attributesNaturalLanguage,
                  firstGroup.attributes.keys[2] == .printerUri || firstGroup.attributes.keys[2] == .jobUri,
                  case let .uri(uri) = firstGroup.attributes.values[2].value
            else {
                throw InvalidRequestError.invalidOperationAttributes
            }

            guard var targetURL = URLComponents(string: uri) else {
                throw InvalidRequestError.invalidTargetUri(uri)
            }

            switch targetURL.scheme {
            case "ipp":
                targetURL.scheme = "http"
            case "ipps":
                targetURL.scheme = "https"
            default:
                throw InvalidRequestError.invalidScheme(targetURL.scheme ?? "<none>")
            }

            targetURL.port = targetURL.port ?? 631
            return targetURL.string!
        }
    }
}

enum InvalidRequestError: Error, CustomStringConvertible {
    case invalidTargetUri(String)
    case invalidScheme(String)
    case invalidOperationAttributes

    var description: String {
        switch self {
        case let .invalidTargetUri(uri):
            return "Invalid target URI: \(uri)"
        case let .invalidScheme(scheme):
            return "Invalid scheme: \(scheme)"
        case .invalidOperationAttributes:
            return "Operation attributes must contain attributesCharset, attributesNaturalLanguage, and a targetUri as the first three attributes."
        }
    }
}
