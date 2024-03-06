import AsyncAlgorithms
import AsyncHTTPClient
import IppProtocol
import NIOCore

public extension HTTPClient {
    /// Executes an IPP request and returns the response.
    /// - Parameter request: The IPP request to execute.
    /// - Parameter data: The data to send with the request.
    ///
    /// - Returns: The IPP response.
    func execute(
        _ request: IppRequest,
        authentication: IppAuthentication? = nil,
        data: consuming HTTPClientRequest.Body? = nil,
        timeout: TimeAmount = .seconds(10),
        maxBytes: Int = 1024 * 1024
    ) async throws -> IppResponse {
        let httpRequest = try HTTPClientRequest(ippRequest: request, authentication: authentication, data: data)
        let httpResponse = try await execute(httpRequest, timeout: timeout)

        if httpResponse.status != .ok {
            throw IppHttpResponseError(response: httpResponse)
        }

        var buffer = try await httpResponse.body.collect(upTo: maxBytes)
        return try IppResponse(buffer: &buffer)
    }
}

public extension HTTPClientRequest {
    /// Creates a HTTP by encoding the IPP request and attaching the data if provided.
    init(ippRequest: IppRequest, authentication: IppAuthentication? = nil, data: consuming Body? = nil) throws {
        try self.init(url: ippRequest.validatedHttpTargetUrl)
        method = .POST
        headers.add(name: "content-type", value: "application/ipp")

        // set auth header if needed
        if let authenticationMode = authentication?.mode {
            switch authenticationMode {
            case .requestingUser(username: _): break // nothing to do
            case let .basic(username: username, password: password):
                let value = HTTPClient.Authorization.basic(username: username, password: password).headerValue
                headers.add(name: "authorization", value: value)
            }
        }

        // maybe pre-size this thing somehow?
        var buffer = ByteBuffer()
        ippRequest.write(to: &buffer)

        if let data {
            // TODO: check out if this is so great - it would be nice know the length
            body = .stream(chain([buffer].async, data), length: .unknown)
        } else {
            body = .bytes(buffer)
        }
    }
}

/// Represents the error when an IPP request fails with an HTTP response that is not 200 OK.
public struct IppHttpResponseError: Error, CustomStringConvertible {
    public let response: HTTPClientResponse

    public var description: String {
        "IPP request failed with response status \(response.status): \(response)"
    }
}
