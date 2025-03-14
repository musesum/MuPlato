// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MuPlato",
    platforms: [.iOS(.v17)],
    products: [.library(name: "MuPlato", targets: ["MuPlato"])],
    dependencies: [
        .package(url: "https://github.com/musesum/MuFlo.git", .branch("main")),
        .package(url: "https://github.com/musesum/MuVision.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MuPlato",
            dependencies: [
                .product(name: "MuVision", package: "MuVision"),
                .product(name: "MuFlo", package: "MuFlo")
            ]),
        .testTarget(
            name: "MuPlatoTests",
            dependencies: ["MuPlato"]),
    ]
)
