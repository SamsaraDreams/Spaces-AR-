// RealityKitMaterialProvider.swift
// Implementación de WallpaperMaterialProviding para RealityKit / iOS 17.
//
// NOTA DE TILING UV:
// RealityKit iOS 17 no expone TextureCoordinateTransform directamente.
// La estrategia es generar el mesh del plano con coordenadas UV escaladas
// (ver ARViewContainer) y usar una textura sin transformación en el material.
// Esta clase sólo construye el PhysicallyBasedMaterial con la textura cargada.

import RealityKit
import UIKit

/// Implementación concreta de `WallpaperMaterialProviding` para RealityKit iOS 17+.
final class RealityKitMaterialProvider: WallpaperMaterialProviding {

    // MARK: - WallpaperMaterialProviding

    func canProvide(for request: WallpaperMaterialRequest) -> Bool {
        UIImage(named: request.wallpaper.textureFile) != nil
    }

    /// Construye el PhysicallyBasedMaterial con la textura cargada desde el bundle.
    /// El tiling UV se logra escalando las UV del mesh en ARViewContainer.
    /// Retorna nil si la textura no existe en el bundle.
    func material(for request: WallpaperMaterialRequest) -> RealityKit.Material? {
        guard let uiImage = UIImage(named: request.wallpaper.textureFile),
              let cgImage = uiImage.cgImage else {
            print("[RealityKitMaterialProvider] Textura no encontrada: \(request.wallpaper.textureFile)")
            return nil
        }

        do {
            // TextureResource.generate(from:options:) disponible desde iOS 15
            let textureResource = try TextureResource.generate(
                from: cgImage,
                options: .init(semantic: .color)
            )

            var material = PhysicallyBasedMaterial()

            // Textura base (el tiling se aplica vía UV del mesh, no aquí)
            let texture = MaterialParameters.Texture(textureResource)
            material.baseColor = .init(texture: texture)

            // Papel tapiz: mate, no metálico
            material.roughness  = .init(floatLiteral: 0.85)
            material.metallic   = .init(floatLiteral: 0.0)

            return material
        } catch {
            print("[RealityKitMaterialProvider] Error generando TextureResource: \(error)")
            return nil
        }
    }
}
