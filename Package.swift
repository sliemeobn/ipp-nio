// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "ipp-nio",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "IppProtocol", targets: ["IppProtocol"]),
        .library(name: "IppClient", targets: ["IppClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.6"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.20.0"),
    ],
    targets: [
        .target(
            name: "IppClient",
            dependencies: [
                .target(name: "IppProtocol"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
        .target(
            name: "IppProtocol",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),
        .testTarget(
            name: "IppTests",
            dependencies: ["IppProtocol", "IppClient"]
        ),
    ]
)

#if os(macOS) || os(Linux) 
package.targets.append(
    .executableTarget(
        name: "PrintPDF",
        dependencies: [
            .target(name: "IppClient"),
        ],
        path: "Examples/PrintPDF",
        exclude: ["hi_mom.pdf"]
    )
)
#endif