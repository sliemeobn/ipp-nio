import IppClient
import Foundation

let pdf = try Data(contentsOf: URL(filePath: "test-files/example.pdf"))

let printer = IppPrinter(
    httpClient: HTTPClient(configuration: .init(certificateVerification: .none)),
    uri: "ipps://macmini.local/printers/EPSON_XP_7100_Series"
)

var jobAttributes = IppAttributes()
jobAttributes[\.jobTemplate.printQuality] = .draft
jobAttributes[\.jobTemplate.copies] = 2

let response2 = try await printer.printJob(
    documentFormat: "application/pdf",
    jobAttributes: jobAttributes,
    data: .bytes(pdf)
)

print(response2)