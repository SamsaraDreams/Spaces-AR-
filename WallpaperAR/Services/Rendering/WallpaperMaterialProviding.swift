// WallpaperMaterialProviding.swift
// Contrato del servicio que construye el material del papel tapiz.
// La implementación con RealityKit (PhysicallyBasedMaterial + tiling UV)
// llega en Fase 3. Aquí se define solo la frontera y el dato de entrada.

import Foundation

/// Parámetros necesarios para construir el material de una pared concreta.
struct WallpaperMaterialRequest: Equatable {
    /// Papel tapiz seleccionado del catálogo.
    let wallpaper: Wallpaper
    /// Superficie sobre la que se aplicará (define el tiling).
    let surface: WallSurface

    /// Tiling calculado con la regla de dominio (repeticiones X/Y).
    var tiling: UVScaleCalculator.TilingResult {
        UVScaleCalculator.tiling(for: surface, patternSpec: wallpaper.patternSpec)
    }
}

/// Servicio que entrega un material listo para asignar a una entidad de RealityKit.
/// El tipo de retorno concreto (`RealityKit.Material`) se define en la
/// implementación de Fase 3 para no acoplar esta frontera a RealityKit.
protocol WallpaperMaterialProviding: AnyObject {
    /// Indica si el proveedor puede construir el material para la petición dada
    /// (p. ej. si la textura existe en el bundle).
    func canProvide(for request: WallpaperMaterialRequest) -> Bool
}
