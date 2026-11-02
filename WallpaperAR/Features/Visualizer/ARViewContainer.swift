// ARViewContainer.swift
// Puente UIViewRepresentable entre SwiftUI y el ARView de RealityKit.
// Gestiona el ciclo de vida del ARView y aplica el material del tapiz
// a los planos verticales detectados por ARKit.

import ARKit
import RealityKit
import SwiftUI

/// Contenedor SwiftUI para `ARView`.
/// Recibe el papel tapiz seleccionado y el proveedor de material,
/// y proyecta la textura sobre cada pared detectada.
struct ARViewContainer: UIViewRepresentable {

    let wallpaper: Wallpaper
    let materialProvider: RealityKitMaterialProvider

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false // la sesión la maneja ARWallDetector

        // Habilitar estadísticas de debug en builds de desarrollo
        #if DEBUG
        arView.debugOptions = [.showFeaturePoints]
        #endif

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        // Re-aplicar material si cambió el tapiz seleccionado
        context.coordinator.updateWallpaper(wallpaper, provider: materialProvider)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(wallpaper: wallpaper, materialProvider: materialProvider)
    }

    // MARK: - Coordinator

    /// Coordinator: observa la sesión AR y aplica/actualiza materiales en los planos.
    final class Coordinator: NSObject, ARSessionDelegate {

        weak var arView: ARView?
        private var currentWallpaper: Wallpaper
        private var materialProvider: RealityKitMaterialProvider

        /// Mapa anchorID → ModelEntity para actualizar sin duplicar
        private var planeEntities: [UUID: ModelEntity] = [:]

        init(wallpaper: Wallpaper, materialProvider: RealityKitMaterialProvider) {
            self.currentWallpaper = wallpaper
            self.materialProvider = materialProvider
        }

        func updateWallpaper(_ wallpaper: Wallpaper, provider: RealityKitMaterialProvider) {
            guard wallpaper != currentWallpaper else { return }
            currentWallpaper = wallpaper
            materialProvider = provider
            // Re-pintar todos los planos existentes
            reapplyAllMaterials()
        }

        // MARK: ARSessionDelegate

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            addOrUpdate(anchors)
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            addOrUpdate(anchors)
        }

        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                planeEntities[anchor.identifier]?.removeFromParent()
                planeEntities.removeValue(forKey: anchor.identifier)
            }
        }

        // MARK: Private

        private func addOrUpdate(_ anchors: [ARAnchor]) {
            guard let arView else { return }

            for anchor in anchors {
                guard let planeAnchor = anchor as? ARPlaneAnchor,
                      planeAnchor.alignment == .vertical else { continue }

                let width  = planeAnchor.planeExtent.width
                let height = planeAnchor.planeExtent.height

                // Construir o reutilizar la entidad
                let entity: ModelEntity
                if let existing = planeEntities[anchor.identifier] {
                    entity = existing
                    // Actualizar dimensiones
                    entity.model?.mesh = .generatePlane(width: width, height: height)
                } else {
                    entity = ModelEntity(mesh: .generatePlane(width: width, height: height))
                    planeEntities[anchor.identifier] = entity

                    let anchorEntity = AnchorEntity(anchor: planeAnchor)
                    anchorEntity.addChild(entity)
                    arView.scene.addAnchor(anchorEntity)
                }

                // Aplicar material
                let surface = WallSurface(
                    orientation: .vertical,
                    widthM: Double(width),
                    heightM: Double(height)
                )
                let request = WallpaperMaterialRequest(
                    wallpaper: currentWallpaper,
                    surface: surface
                )
                if let mat = materialProvider.material(for: request) {
                    entity.model?.materials = [mat]
                }
            }
        }

        private func reapplyAllMaterials() {
            guard let arView else { return }
            for anchor in arView.session.currentFrame?.anchors ?? [] {
                addOrUpdate([anchor])
            }
        }
    }
}
