// ARViewContainer.swift
// Puente UIViewRepresentable entre SwiftUI y el ARView de RealityKit.
// El tiling UV se logra generando un MeshResource con coordenadas UV
// escaladas según tilesX/tilesY — compatible con iOS 17.

import ARKit
import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {

    let wallpaper: Wallpaper
    let materialProvider: RealityKitMaterialProvider

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        #if DEBUG
        arView.debugOptions = [.showFeaturePoints]
        #endif

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        context.coordinator.updateWallpaper(wallpaper, provider: materialProvider)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(wallpaper: wallpaper, materialProvider: materialProvider)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, ARSessionDelegate {

        weak var arView: ARView?
        private var currentWallpaper: Wallpaper
        private var materialProvider: RealityKitMaterialProvider
        private var planeEntities: [UUID: ModelEntity] = [:]

        init(wallpaper: Wallpaper, materialProvider: RealityKitMaterialProvider) {
            self.currentWallpaper = wallpaper
            self.materialProvider = materialProvider
        }

        func updateWallpaper(_ wallpaper: Wallpaper, provider: RealityKitMaterialProvider) {
            guard wallpaper != currentWallpaper else { return }
            currentWallpaper = wallpaper
            materialProvider = provider
            reapplyAllMaterials()
        }

        // MARK: - ARSessionDelegate

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

        // MARK: - Private

        private func addOrUpdate(_ anchors: [ARAnchor]) {
            guard let arView else { return }

            for anchor in anchors {
                guard let planeAnchor = anchor as? ARPlaneAnchor,
                      planeAnchor.alignment == .vertical else { continue }

                let w = planeAnchor.planeExtent.width
                let h = planeAnchor.planeExtent.height

                // Calcular tiling UV
                let surface = WallSurface(
                    orientation: .vertical,
                    widthM: Double(w),
                    heightM: Double(h)
                )
                let request = WallpaperMaterialRequest(
                    wallpaper: currentWallpaper,
                    surface: surface
                )
                let tiling = request.tiling

                // Mesh con UV escaladas para el tiling
                let mesh = makeScaledUVPlane(
                    width: w,
                    height: h,
                    tilesX: Float(tiling.tilesX),
                    tilesY: Float(tiling.tilesY)
                )

                if let existing = planeEntities[anchor.identifier] {
                    existing.model?.mesh = mesh
                    if let mat = materialProvider.material(for: request) {
                        existing.model?.materials = [mat]
                    }
                } else {
                    let entity = ModelEntity(mesh: mesh)
                    if let mat = materialProvider.material(for: request) {
                        entity.model?.materials = [mat]
                    }
                    planeEntities[anchor.identifier] = entity

                    let anchorEntity = AnchorEntity(anchor: planeAnchor)
                    anchorEntity.addChild(entity)
                    arView.scene.addAnchor(anchorEntity)
                }
            }
        }

        private func reapplyAllMaterials() {
            guard let arView else { return }
            for anchor in arView.session.currentFrame?.anchors ?? [] {
                addOrUpdate([anchor])
            }
        }

        /// Genera un MeshResource de plano con UV escaladas para repetir la textura.
        /// RealityKit no expone TextureCoordinateTransform en iOS 17, así que
        /// escalamos las coordenadas UV directamente en el mesh.
        private func makeScaledUVPlane(
            width: Float,
            height: Float,
            tilesX: Float,
            tilesY: Float
        ) -> MeshResource {
            // Vértices del plano (2 triángulos)
            // Posiciones en espacio local del anchor
            let hw = width  / 2
            let hh = height / 2

            var descr = MeshDescriptor(name: "WallpaperPlane")

            // 4 vértices: bottom-left, bottom-right, top-left, top-right
            descr.positions = MeshBuffer([
                SIMD3<Float>(-hw, -hh, 0),
                SIMD3<Float>( hw, -hh, 0),
                SIMD3<Float>(-hw,  hh, 0),
                SIMD3<Float>( hw,  hh, 0),
            ])

            // UV escaladas según tiling
            descr.textureCoordinates = MeshBuffer([
                SIMD2<Float>(0,       0      ),
                SIMD2<Float>(tilesX,  0      ),
                SIMD2<Float>(0,       tilesY ),
                SIMD2<Float>(tilesX,  tilesY ),
            ])

            // Normales apuntando hacia -Z (hacia la cámara cuando el plano es vertical)
            descr.normals = MeshBuffer([
                SIMD3<Float>(0, 0, -1),
                SIMD3<Float>(0, 0, -1),
                SIMD3<Float>(0, 0, -1),
                SIMD3<Float>(0, 0, -1),
            ])

            // 2 triángulos formando el quad
            descr.primitives = .triangles([
                0, 1, 2,
                1, 3, 2,
            ])

            return (try? MeshResource.generate(from: [descr])) ??
                   .generatePlane(width: width, height: height)
        }
    }
}
