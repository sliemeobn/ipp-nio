// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ipp-nio",
    platforms: [
        .macOS(.v13),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "IppProtocol", targets: ["IppProtocol"]),
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
        .executableTarget(
            name: "Examples",
            dependencies: [
                .target(name: "IppClient"),
            ]
        ),
        .testTarget(
            name: "IppTests",
            dependencies: ["IppProtocol", "IppClient"]
        ),
    ]
)
