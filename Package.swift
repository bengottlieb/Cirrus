// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	 name: "Cirrus",
	  platforms: [
				  .macOS(.v12),
				  .iOS(.v15),
				  .watchOS(.v7)
			],
	 products: [
		  // Products define the executables and libraries produced by a package, and make them visible to other packages.
		  .library(
				name: "Cirrus",
				targets: ["Cirrus"]),
	 ],
	 dependencies: [
		.package(url: "https://github.com/ios-tooling/Suite", from: "1.3.5"),
	 ],
	 targets: [
		  // Targets are the basic building blocks of a package. A target can define a module or a test suite.
		  // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Cirrus",
            dependencies: ["Suite"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
	 ]
)
