import AsyncHTTPClient
import IppProtocol

/// Implements the ``IppPrinterObject`` using a HTTPClient.
public struct IppPrinter: IppPrinterObject, Sendable {
    public var httpClient: HTTPClient
    public var uri: String
    public var authentication: IppAuthentication?
    public var language: String
    public var version: IppVersion

    public init(
        httpClient: HTTPClient,
        uri: String,
        authentication: IppAuthentication? = nil,
        language: String = "en",
        version: IppVersion = .v1_1
    ) {
        self.httpClient = httpClient
        self.uri = uri
        self.authentication = authentication
        self.language = language
        self.version = version
    }

    public func makeNewRequest(operation: IppOperationId) -> IppRequest {
        IppRequest(
            printerUri: uri,
            operation: operation,
            requestingUserName: authentication?.requestingUserName,
            attributesNaturalLanguage: language,
            version: version
        )
    }

    public func execute(request: IppRequest, data: HTTPClientRequest.Body?) async throws -> IppResponse {
        try await httpClient.execute(request, authentication: authentication, data: data)
    }
}

public extension HTTPClient {
    func ippPrinter(uri: String, language: String = "en", version: IppVersion = .v1_1) -> IppPrinter {
        IppPrinter(httpClient: self, uri: uri, language: language, version: version)
    }
}

/// Represents the authentication mode for an IPP request.
public struct IppAuthentication: Sendable {
    enum Mode {
        case requestingUser(username: String)
        case basic(username: String, password: String)
    }

    var mode: Mode

    /// Sets the "requesting-user` attribute on every request.
    public static func requestingUser(username: String) -> Self {
        Self(mode: .requestingUser(username: username))
    }

    /// Uses HTTP basic authentication for every request.
    public static func basic(username: String, password: String) -> Self {
        Self(mode: .basic(username: username, password: password))
    }

    var requestingUserName: String {
        switch mode {
        case let .requestingUser(username), let .basic(username, _):
            return username
        }
    }
}
