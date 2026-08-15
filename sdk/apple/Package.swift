// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotchAgentDeskProtocol",
    platforms: [.macOS(.v14)],
    products: [.library(name: "NotchAgentDeskProtocol", targets: ["NotchAgentDeskProtocol"])],
    targets: [
        .target(name: "NotchAgentDeskProtocol"),
        .testTarget(name: "NotchAgentDeskProtocolTests", dependencies: ["NotchAgentDeskProtocol"]),
    ]
)
