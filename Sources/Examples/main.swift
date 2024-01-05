import AsyncHTTPClient
import IppClient

let printer = IppPrinter(
    httpClient: HTTPClient(configuration: .init(certificateVerification: .none)),
    uri: "ipps://epsonafa529.local/ipp/print"
)

let response2 = try await printer.printJob(
    jobName: "test",
    jobAttributes: [.copies: .init(.integer(1))],
    data: .bytes(.init(string: "FOOO"))
)

print(response2)
