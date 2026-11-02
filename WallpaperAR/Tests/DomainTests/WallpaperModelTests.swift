// WallpaperModelTests.swift
// Tests del modelo Wallpaper y WallSurface.

import XCTest
@testable import WallpaperARDomain

final class WallpaperModelTests: XCTestCase {

    func testWallpaperEquality() {
        let id = UUID()
        let spec = PatternSpec(patternWidthM: 0.53, patternHeightM: 0.53,
                               textureWidthPx: 560, textureHeightPx: 560)
        let a = Wallpaper(id: id, name: "Floral", textureFile: "floral.jpg",
                          patternSpec: spec, tileable: true)
        let b = Wallpaper(id: id, name: "Floral", textureFile: "floral.jpg",
                          patternSpec: spec, tileable: true)
        XCTAssertEqual(a, b)
    }

    func testWallSurfaceArea() {
        let surface = WallSurface(orientation: .vertical, widthM: 4.0, heightM: 2.5)
        XCTAssertEqual(surface.areaM2, 10.0, accuracy: 1e-9)
    }

    func testWallSurfaceIdentifiable() {
        let s1 = WallSurface(orientation: .vertical, widthM: 3.0, heightM: 2.5)
        let s2 = WallSurface(orientation: .vertical, widthM: 3.0, heightM: 2.5)
        // IDs distintos aunque dimensiones iguales
        XCTAssertNotEqual(s1.id, s2.id)
    }
}
