// Wallpaper.swift
// Modelo de dominio – representa un papel tapiz en el catálogo.
// Sin dependencias de ARKit/RealityKit → compila en Linux (CI).

import Foundation

/// Identificador único de un papel tapiz en el catálogo.
public typealias WallpaperID = UUID

/// Un papel tapiz con su especificación física y de textura.
public struct Wallpaper: Identifiable, Equatable, Sendable {

    public let id: WallpaperID

    /// Nombre descriptivo para mostrar en la UI.
    public let name: String

    /// Nombre del archivo de textura (sin ruta, e.g. "tapiz_floral.jpg").
    public let textureFile: String

    /// Especificación del patrón físico (dimensiones reales en metros).
    public let patternSpec: PatternSpec

    /// Si el patrón es continuo/tileable (sin costuras visibles).
    public let tileable: Bool

    /// Notas opcionales (colección, proveedor, etc.).
    public let notes: String?

    public init(
        id: WallpaperID = UUID(),
        name: String,
        textureFile: String,
        patternSpec: PatternSpec,
        tileable: Bool = true,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.textureFile = textureFile
        self.patternSpec = patternSpec
        self.tileable = tileable
        self.notes = notes
    }
}
