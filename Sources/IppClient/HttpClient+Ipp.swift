import AsyncHTTPClient
import IppProtocol
import NIOCore
import AsyncAlgorithms

public extension HTTPClient {
    /// Executes an IPP request and returns the response.
    /// - Parameter request: The IPP request to execute.
    /// - Parameter data: The data to send with the request.
    func execute(_ request: IppRequest, data: consuming HTTPClientRequest.Body? = nil, timeout: TimeAmount = .seconds(10)) async throws -> IppResponse {
        let httpRequest = try HTTPClientRequest(ippRequest: request, data: data)
        let httpResponse = try await self.execute(httpRequest, timeout: timeout)

        if httpResponse.status != .ok {
            throw IppClientError(message: "HTTP status \(httpResponse)")
        }

        var buffer = try await httpResponse.body.collect(upTo: 20 * 1024)
        return try IppResponse(buffer: &buffer)
    }
}

public extension HTTPClientRequest {
    /// Creates a HTTP by encoding the IPP request and attaching the data if provided.
    init(ippRequest: IppRequest, data: consuming Body? = nil) throws {
        let uri = try ippRequest.getTargetUriIfValidOrThrow()

        self.init(url: uri)
        self.method = .POST
        self.headers.add(name: "content-type", value: "application/ipp")
        // TODO: auth

        // maybe pre-size this thing somehow?
        var buffer = ByteBuffer()
        ippRequest.write(to: &buffer)

        if let data {
            //TODO: check out if this is so great - it would be nice know the length
            self.body = .stream(chain([buffer].async, data), length: .unknown)
        } else {
            self.body = .bytes(buffer)
        }
    }
}

public struct IppClientError: Error, Sendable {
    public let message: String
}