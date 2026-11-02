// RealityKitMaterialProvider.swift
// Implementación de WallpaperMaterialProviding usando RealityKit.
// Carga la textura desde el bundle de la app, aplica UV tiling con
// PhysicallyBasedMaterial y devuelve el material listo para asignar
// a una ModelEntity de RealityKit.

import RealityKit
import UIKit

/// Implementación concreta de `WallpaperMaterialProviding` para RealityKit.
/// Construye un `PhysicallyBasedMaterial` con la textura del papel tapiz
/// repetida según el tiling UV calculado por `UVScaleCalculator`.
final class RealityKitMaterialProvider: WallpaperMaterialProviding {

    // MARK: - WallpaperMaterialProviding

    func canProvide(for request: WallpaperMaterialRequest) -> Bool {
        UIImage(named: request.wallpaper.textureFile) != nil
    }

    /// Construye y devuelve el material PBR listo para usar.
    /// Retorna `nil` si la textura no existe en el bundle.
    func material(for request: WallpaperMaterialRequest) -> RealityKit.Material? {
        guard let uiImage = UIImage(named: request.wallpaper.textureFile) else {
            print("[RealityKitMaterialProvider] Textura no encontrada: \(request.wallpaper.textureFile)")
            return nil
        }

        // Construir la textura con el tiling UV calculado
        let tiling = request.tiling
        var material = PhysicallyBasedMaterial()

        // Crear TextureResource desde UIImage
        guard let cgImage = uiImage.cgImage,
              let textureResource = try? TextureResource(
                  image: cgImage,
                  withName: request.wallpaper.textureFile,
                  options: .init(semantic: .color)
              ) else {
            print("[RealityKitMaterialProvider] No se pudo crear TextureResource.")
            return nil
        }

        // Aplicar la textura con transform de UV para el tiling
        var baseColor = PhysicallyBasedMaterial.BaseColor()
        let tilingTransform = TextureCoordinateTransform(
            scale: SIMD2<Float>(Float(tiling.tilesX), Float(tiling.tilesY)),
            rotation: 0
        )
        baseColor.texture = .init(
            textureResource,
            sampler: MaterialParameters.Texture.Sampler(
                wrap: (.repeat, .repeat),
                mipFilter: .linear,
                magFilter: .linear,
                minFilter: .linear
            ),
            transform: tilingTransform
        )
        material.baseColor = baseColor

        // Superficie mate — papel tapiz no es metálico ni brillante
        material.roughness = .init(floatLiteral: 0.85)
        material.metallic  = .init(floatLiteral: 0.0)

        return material
    }
}
