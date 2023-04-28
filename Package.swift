// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "MuPlato",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MuPlato",
            targets: ["MuPlato"]),
    ],
    dependencies: [
        .package(url: "https://github.com/musesum/MuMetal.git", from: "0.23.0"),
        .package(url: "https://github.com/musesum/MuColor.git", from: "0.23.0"),
    ],
    targets: [
        .target(
            name: "MuPlato",
            dependencies: [
                .product(name: "MuMetal", package: "MuMetal"),
                .product(name: "MuColor", package: "MuColor")],
            resources: [.copy("Resources")]),
        .testTarget(
            name: "MuPlatoTests",
            dependencies: ["MuPlato"]),
    ]
)
