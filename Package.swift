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
        .package(url: "https://github.com/musesum/MuFlo.git", .branch("main")),
        .package(url: "https://github.com/musesum/MuMetal.git",  branch: "main"),
        .package(url: "https://github.com/musesum/MuColor.git",  branch: "main"),
        .package(url: "https://github.com/musesum/MuVision.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MuPlato",
            dependencies: [
                .product(name: "MuMetal", package: "MuMetal"),
                .product(name: "MuColor", package: "MuColor"), 
                .product(name: "MuVision", package: "MuVision"),
                .product(name: "MuFlo", package: "MuFlo")
            ]),
        .testTarget(
            name: "MuPlatoTests",
            dependencies: ["MuPlato"]),
    ]
)
