import AsyncHTTPClient
import IppProtocol

public struct IppPrinter: IppPrinterObject, Sendable {
    public var httpClient: HTTPClient
    public var uri: String
    public var language: String
    public var version: IppVersion

    public init(httpClient: HTTPClient, uri: String, language: String = "en", version: IppVersion = .v1_1) {
        self.httpClient = httpClient
        self.uri = uri
        self.language = language
        self.version = version
    }

    public func makeNewRequest(operation: IppOperationId) -> IppRequest {
        IppRequest(printerUri: uri, operation: operation, attributesNaturalLanguage: language, version: version)
        //TODO: add user/auth here
    }

    public func execute(request: IppProtocol.IppRequest, data: HTTPClientRequest.Body?) async throws -> IppResponse {
        try await httpClient.execute(request, data: data)
    }
}

public extension HTTPClient {
    func ippPrinter(uri: String, language: String = "en", version: IppVersion = .v1_1) -> IppPrinter {
        IppPrinter(httpClient: self, uri: uri, language: language, version: version)
    }
}