// swift-tools-version:5.9
// WallpaperAR – definición del paquete Swift
// Dominio puro (sin ARKit/RealityKit) → compila en CI Linux/macOS
// ARKit y RealityKit se enlazan solo en el target de la App (iOS)

import PackageDescription


let package = Package(
    name: "WallpaperAR",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "WallpaperARDomain", targets: ["WallpaperARDomain"]),
    ],
    targets: [
        // ── Dominio puro: modelos + reglas de escala UV ──────────────────
        .target(
            name: "WallpaperARDomain",
            path: "WallpaperAR/Domain",
            swiftSettings: [
                .define("DEBUG", .when(configuration: .debug))
            ]
        ),
        // ── Tests del dominio (corren en CI sin dispositivo) ─────────────
        .testTarget(
            name: "WallpaperARDomainTests",
            dependencies: ["WallpaperARDomain"],
            path: "WallpaperAR/Tests"
        ),
    ]
)
