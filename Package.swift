// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "giti",
	dependencies: [
	  .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.1"),
	],
    targets: [
        .executableTarget(
			name: "giti",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			],
			path: "Sources"
		),
    ]
)
