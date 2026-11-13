// CatalogLoaderTests.swift
// Valida la decodificación de catalog.json hacia el modelo de dominio.
// Pure Foundation (sin ARKit) → corre en CI Linux/macOS sin dispositivo.

import XCTest
@testable import WallpaperARDomain

final class CatalogLoaderTests: XCTestCase {

    // ── 1. JSON válido con un tapiz → decodifica correctamente ──────────
    func testLoadsValidCatalog() throws {
        let json = """
        [
          {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "name": "Tapiz Referencia (53 cm)",
            "textureFile": "tapiz_referencia.jpg",
            "patternWidthM": 0.53,
            "patternHeightM": 0.53,
            "textureWidthPx": 560,
            "textureHeightPx": 560,
            "rollLengthM": 10.0,
            "rollWidthM": 0.53,
            "tileable": true,
            "notes": "Referencia del proyecto."
          }
        ]
        """
        let data = Data(json.utf8)
        let wallpapers = try CatalogLoader.loadWallpapers(from: data)

        XCTAssertEqual(wallpapers.count, 1)
        let w = wallpapers[0]
        XCTAssertEqual(w.name, "Tapiz Referencia (53 cm)")
        XCTAssertEqual(w.textureFile, "tapiz_referencia.jpg")
        XCTAssertEqual(w.patternSpec.patternWidthM, 0.53, accuracy: 1e-9)
        XCTAssertEqual(w.id, UUID(uuidString: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"))
        XCTAssertTrue(w.tileable)
    }

    // ── 2. Entrada con dimensiones inválidas se descarta, no crashea ────
    func testDropsInvalidEntryWithoutCrashing() throws {
        let json = """
        [
          {
            "name": "Tapiz Roto",
            "textureFile": "roto.jpg",
            "patternWidthM": 0,
            "patternHeightM": 0.53
          },
          {
            "name": "Tapiz Válido",
            "textureFile": "valido.jpg",
            "patternWidthM": 0.53,
            "patternHeightM": 0.53
          }
        ]
        """
        let wallpapers = try CatalogLoader.loadWallpapers(from: Data(json.utf8))
        XCTAssertEqual(wallpapers.count, 1)
        XCTAssertEqual(wallpapers[0].name, "Tapiz Válido")
    }

    // ── 3. textureFile vacío se descarta ─────────────────────────────────
    func testDropsEntryWithEmptyTextureFile() throws {
        let json = """
        [
          { "name": "Sin textura", "textureFile": "", "patternWidthM": 0.53, "patternHeightM": 0.53 }
        ]
        """
        let wallpapers = try CatalogLoader.loadWallpapers(from: Data(json.utf8))
        XCTAssertTrue(wallpapers.isEmpty)
    }

    // ── 4. id ausente o inválido genera un UUID nuevo en vez de fallar ───
    func testMissingOrInvalidIdGeneratesFallbackUUID() throws {
        let json = """
        [
          { "name": "Sin id", "textureFile": "x.jpg", "patternWidthM": 0.53, "patternHeightM": 0.53 },
          { "id": "no-es-un-uuid", "name": "Id inválido", "textureFile": "y.jpg", "patternWidthM": 0.53, "patternHeightM": 0.53 }
        ]
        """
        let wallpapers = try CatalogLoader.loadWallpapers(from: Data(json.utf8))
        XCTAssertEqual(wallpapers.count, 2)
        // No crashea y asigna un UUID válido en ambos casos.
        XCTAssertNotNil(wallpapers[0].id)
        XCTAssertNotNil(wallpapers[1].id)
    }

    // ── 5. JSON malformado lanza LoadError.decodingFailed ───────────────
    func testMalformedJSONThrowsDecodingFailed() {
        let data = Data("esto no es json válido".utf8)
        XCTAssertThrowsError(try CatalogLoader.loadWallpapers(from: data)) { error in
            guard case CatalogLoader.LoadError.decodingFailed = error else {
                return XCTFail("Se esperaba LoadError.decodingFailed, se obtuvo \(error)")
            }
        }
    }

    // ── 6. Recurso inexistente en bundle lanza resourceNotFound ─────────
    // Se usa `.main` (siempre disponible, sin codegen de SwiftPM) a propósito:
    // el objetivo es verificar el camino de error cuando el recurso no existe
    // en el bundle dado, no depender de `Bundle.module` (que el target de
    // tests no genera porque no declara `resources:` en Package.swift).
    func testMissingBundleResourceThrowsResourceNotFound() {
        XCTAssertThrowsError(
            try CatalogLoader.loadWallpapers(resourceName: "no_existe_catalogo", bundle: .main)
        ) { error in
            guard case CatalogLoader.LoadError.resourceNotFound = error else {
                return XCTFail("Se esperaba LoadError.resourceNotFound, se obtuvo \(error)")
            }
        }
    }
}
