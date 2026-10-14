// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Birding", platforms: [.macOS(.v13)], products: [.executable(name: "Birding", targets: ["Birding"])], targets: [.target(name: "BirdingCore", resources: [.copy("Resources/species.json")]), .executableTarget(name: "Birding", dependencies: ["BirdingCore"]), .testTarget(name: "BirdingCoreTests", dependencies: ["BirdingCore"])])
