// WallpaperMaterialProviding.swift
// Contrato del servicio que construye el material del papel tapiz.

import RealityKit

/// Parámetros necesarios para construir el material de una pared concreta.
struct WallpaperMaterialRequest: Equatable {
    /// Papel tapiz seleccionado del catálogo.
    let wallpaper: Wallpaper
    /// Superficie sobre la que se aplicará (define el tiling).
    let surface: WallSurface

    /// Tiling calculado con la regla de dominio (repeticiones X/Y).
    var tiling: UVScaleCalculator.TilingResult {
        UVScaleCalculator.tiling(
            wallWidthM:  surface.widthM,
            wallHeightM: surface.heightM,
            patternSpec: wallpaper.patternSpec
        )
    }
}

/// Servicio que entrega un material listo para asignar a una entidad de RealityKit.
protocol WallpaperMaterialProviding: AnyObject {
    /// Indica si el proveedor puede construir el material para la petición dada.
    func canProvide(for request: WallpaperMaterialRequest) -> Bool

    /// Construye y devuelve el material. Retorna `nil` si la textura no está disponible.
    func material(for request: WallpaperMaterialRequest) -> RealityKit.Material?
}
