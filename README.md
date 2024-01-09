# ipp-nio: Internet Printing Protocol for Swift

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsliemeobn%2Fipp-nio%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/sliemeobn/ipp-nio)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fsliemeobn%2Fipp-nio%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/sliemeobn/ipp-nio)

An implementation of the [Internet Printing Protocol (IPP)](https://www.rfc-editor.org/rfc/rfc8011) in pure swift, based on [swift-nio](https://github.com/apple/swift-nio) and [async-http-client](https://github.com/swift-server/async-http-client).

This library allows you to communicate with virtually any network printer directly without any drivers or OS dependencies. It provides an easy API for encoding and exchanging IPP 1.1 requests and responses and a flexible, swifty way to work with attributes in a stongly-typed manner.

**WARNING:** This package is fresh out of oven, you'll be part of the battle-testing phase. See the [implementation status](#status-of-implementation) below.

## Add `ipp-nio` to your package
```swift
// Add to package dependencies
.package(url: "https://github.com/sliemeobn/ipp-nio.git", from: "0.1.0"),
```
```swift
// Add to your target depencies
dependencies: [
    .product(name: "IppClient", package: "ipp-nio"),
]
```

## Features

The library's feature set is roughly organized in four layers:

### IppProtocol Module
- IppRequest/IppResponse encoding and decoding into the [IPP wire format](https://www.rfc-editor.org/rfc/rfc8010)
- Flexibly typed attribute accessors based on the [semantic model](https://www.rfc-editor.org/rfc/rfc8011)
- A simple high-level API to execute common operations directly (ie: print this file)

### IppClient Module
- The actual implementation using HTTPClient as the transfer mechanism to execute IPP operations via HTTP

## Usage

### Print a PDF
```swift
import struct Foundation.Data
import IppClient

let printer = IppPrinter(
    httpClient: HTTPClient(configuration: .init(certificateVerification: .none)),
    uri: "ipps://my-printer/ipp/print"
)

let pdf = try Data(contentsOf: .init(fileURLWithPath: "myfile.pdf"))

let response = try await printer.printJob(
    documentFormat: "application/pdf",
    data: .bytes(pdf)
)

if response.statusCode.class == .successful {
    print("Print job submitted")
} else {
    print("Print job failed with status \(response.statusCode) \(response[operation: \.statusMessage])")
}
```

### Setting job template attributes
```swift
var jobAttributes = IppAttributes()
jobAttributes[\.jobTemplate.copies] = 2
jobAttributes[\.jobTemplate.orientationRequested] = .landscape
jobAttributes["some-custom-thing"] = .init(.keyword("some-value"))

let response = try await printer.printJob(
    documentName: "myfile.pdf",
    jobAttributes: jobAttributes,
    data: .stream(myFileAsStream)
)
```

### Requesting a job's state 
```swift
let response = try await printer.printJob(data: .bytes(myData))
guard let jobId = response[job: \.jobId] else { exit(1) }

let job = printer.job(jobId)

while true {
    let response = try await job.getJobAttributes(requestedAttributes: [.jobState])
    guard let jobState = response[job: \.jobState] else {
        print("Failed to get job state")
        exit(1)
    }

    switch jobState {
    case .aborted, .canceled, .completed:
        print("Job ended with state \(jobState)")
        exit(0)
    default:
        print("Job state is \(jobState)")
    }

    try await Task.sleep(for: .seconds(3))
}
```

### Setting authentication
```swift
// "basic" mode
let printer = IppPrinter(
    httpClient: HTTPClient(configuration: .init(certificateVerification: .none)),
    uri: "ipps://my-printer/ipp/print",
    authentication: .basic(username: "user", password: "top-secret")
)

// "requesting-user" mode
let printer = IppPrinter(
    httpClient: HTTPClient(configuration: .init(certificateVerification: .none)),
    uri: "ipps://my-printer/ipp/print",
    authentication: .requestingUser(username: "user")
)

```

### Working with raw payloads
```swift
import IppProtocol
import NIOCore

var request = IppRequest(
        version: .v1_1,
        operationId: .holdJob,
        requestId: 1
    )

request[.operation][.attributesCharset] = .init(.charset("utf-8"))
request[.operation][.attributesNaturalLanguage] = .init(.naturalLanguage("en-us"))
request[.operation][.printerUri] = .init(.uri("ipp://localhost:631/printers/ipp-printer"))
request[.job]["my-crazy-attribute"] = .init(.enumValue(420), .enumValue(69))

var bytes = ByteBuffer()
request.write(to: &bytes)
let read = try! IppRequest(buffer: &bytes)

print(request == read) // true
```

## What is my printer's IPP URL?

Most printers are discoverable via DNS-SD/Bonjour, any DNS-SD browser should show their information. (eg: [Discovery](https://apps.apple.com/ca/app/discovery-dns-sd-browser/id1381004916?mt=12) for macOS).

The `rp` value is the URL path (usually `/ipp/print`), the scheme is always `ipp://` or `ipps://`.

On macOS, shared printers are also exposed via IPP. (ie: any printer can be a network printer with a server in the middle)

## Status of implementation

The basic, low-level encoding and transfer is robust and should fulfill all needs.
The *semantic model* only covers the most basic attributes for now, but can be extended quite easily as needed.

Since the library is written with custom extensions in mind, it should be quite simple to extend to any use case even without direct support.

Missing:
 - consistent documentation
 - top-level APIs for all operations
 - support for CUPS operations
 - support IPP 2.x features

Anything you would like to have added? Just ping me, also "pull requests welcome" ^^