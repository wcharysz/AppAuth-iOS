// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AppAuth",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "AppAuth",
            targets: ["AppAuth"]
        )
    ],
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
