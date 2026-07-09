// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AppAuth",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ], products: [
        .library(
            name: "AppAuth",
            targets: ["AppAuth"]
        )
    ], dependencies: [.package(url: "https://github.com/apple/swift-http-types", from: "1.5.1")],
    targets: [
        .target(
            name: "AppAuth",
            path: "Sources/AppAuth",
            resources: [.copy("Resources/PrivacyInfo.xcprivacy")],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "AppAuthTests",
            dependencies: ["AppAuth"],
            path: "Tests/AppAuthTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
