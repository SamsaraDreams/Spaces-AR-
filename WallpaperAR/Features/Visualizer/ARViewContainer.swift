// ARViewContainer.swift
// Puente UIViewRepresentable entre SwiftUI y el ARView de RealityKit.
//
// ARQUITECTURA:
// El Coordinator es el único dueño de la ARSession. Inicia la sesión AR,
// actúa como ARSessionDelegate, detecta planos verticales y coloca entidades.
// No depende de ARWallDetector — así el ARView y la sesión son el mismo objeto.
//
// TILING UV:
// RealityKit iOS 17 no expone TextureCoordinateTransform.
// Se generan UVs escaladas en el MeshDescriptor (makeScaledUVPlane).

import ARKit
import RealityKit
import SwiftUI

struct ARViewContainer: UIViewRepresentable {

    let wallpaper: Wallpaper
    let materialProvider: RealityKitMaterialProvider
    /// Callback para notificar al ViewModel de superficies detectadas.
    var onSurfaceUpdate: ((WallSurface) -> Void)?
    /// Callback para notificar fallos de la sesión AR (permiso de cámara
    /// denegado, dispositivo no compatible, interrupción no recuperable).
    /// Antes de este callback estos fallos solo se registraban con `print`
    /// en builds DEBUG: en Release el usuario no tenía ninguna señal de
    /// que algo había fallado, y la UI quedaba indefinidamente en estado
    /// "buscando pared" sin explicación.
    var onSessionError: ((String) -> Void)?

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        #if DEBUG
        arView.debugOptions = [.showFeaturePoints]
        #endif

        context.coordinator.setup(arView: arView)
        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        context.coordinator.onSurfaceUpdate = onSurfaceUpdate
        context.coordinator.onSessionError = onSessionError
        context.coordinator.updateWallpaper(wallpaper, provider: materialProvider)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(wallpaper: wallpaper,
                    materialProvider: materialProvider,
                    onSurfaceUpdate: onSurfaceUpdate,
                    onSessionError: onSessionError)
    }

    /// Detiene la sesión AR cuando SwiftUI desmonta la vista.
    /// Sin esto la cámara sigue activa al volver a ContentView.
    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.stopSession()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, ARSessionDelegate {

        weak var arView: ARView?
        private var currentWallpaper: Wallpaper
        private var materialProvider: RealityKitMaterialProvider
        private var planeEntities: [UUID: ModelEntity] = [:]
        var onSurfaceUpdate: ((WallSurface) -> Void)?
        var onSessionError: ((String) -> Void)?

        init(wallpaper: Wallpaper,
             materialProvider: RealityKitMaterialProvider,
             onSurfaceUpdate: ((WallSurface) -> Void)?,
             onSessionError: ((String) -> Void)?) {
            self.currentWallpaper = wallpaper
            self.materialProvider = materialProvider
            self.onSurfaceUpdate = onSurfaceUpdate
            self.onSessionError = onSessionError
        }

        /// Configura el ARView y arranca la sesión AR.
        func setup(arView: ARView) {
            self.arView = arView
            arView.session.delegate = self
            startSession(in: arView)
        }

        func startSession(in arView: ARView) {
            guard ARWorldTrackingConfiguration.isSupported else {
                #if DEBUG
                print("[ARViewContainer] ARWorldTracking no soportado.")
                #endif
                let message = "Este dispositivo no es compatible con el seguimiento de mundo de ARKit."
                DispatchQueue.main.async { [weak self] in
                    self?.onSessionError?(message)
                }
                return
            }
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = .vertical
            config.environmentTexturing = .none
            arView.session.run(config,
                               options: [.resetTracking, .removeExistingAnchors])
            #if DEBUG
            print("[ARViewContainer] Sesión AR iniciada.")
            #endif
        }

        func stopSession() {
            arView?.session.pause()
        }

        func updateWallpaper(_ wallpaper: Wallpaper,
                             provider: RealityKitMaterialProvider) {
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

        func session(_ session: ARSession, didFailWithError error: Error) {
            #if DEBUG
            print("[ARViewContainer] Error de sesión: \(error.localizedDescription)")
            #endif
            let message = "No se pudo iniciar la cámara AR: \(error.localizedDescription). Verifica el permiso de Cámara en Ajustes."
            DispatchQueue.main.async { [weak self] in
                self?.onSessionError?(message)
            }
        }

        func sessionWasInterrupted(_ session: ARSession) {
            #if DEBUG
            print("[ARViewContainer] Sesión interrumpida.")
            #endif
        }

        func sessionInterruptionEnded(_ session: ARSession) {
            guard let arView else { return }
            startSession(in: arView)
        }

        // MARK: - Private

        private func addOrUpdate(_ anchors: [ARAnchor]) {
            guard let arView else { return }

            for anchor in anchors {
                guard let planeAnchor = anchor as? ARPlaneAnchor,
                      planeAnchor.alignment == .vertical else { continue }

                let w = planeAnchor.planeExtent.width
                let h = planeAnchor.planeExtent.height
                guard w > 0.1, h > 0.1 else { continue }

                // Notificar al ViewModel
                let surface = WallSurface(orientation: .vertical,
                                          widthM: Double(w),
                                          heightM: Double(h))
                DispatchQueue.main.async { [weak self] in
                    self?.onSurfaceUpdate?(surface)
                }

                // Calcular tiling UV
                let request = WallpaperMaterialRequest(wallpaper: currentWallpaper,
                                                       surface: surface)
                let tiling = request.tiling

                let mesh = makeScaledUVPlane(width: w, height: h,
                                             tilesX: Float(tiling.tilesX),
                                             tilesY: Float(tiling.tilesY))

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
            let anchors = arView.session.currentFrame?.anchors ?? []
            addOrUpdate(Array(anchors))
        }

        /// Genera un MeshResource de plano con UV escaladas para repetir la textura.
        /// RealityKit iOS 17 no expone TextureCoordinateTransform, así que
        /// escalamos las coordenadas UV directamente en el mesh.
        private func makeScaledUVPlane(width: Float, height: Float,
                                       tilesX: Float, tilesY: Float) -> MeshResource {
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

            // UV escaladas según tiling (iOS 17: sin TextureCoordinateTransform)
            descr.textureCoordinates = MeshBuffer([
                SIMD2<Float>(0,      0      ),
                SIMD2<Float>(tilesX, 0      ),
                SIMD2<Float>(0,      tilesY ),
                SIMD2<Float>(tilesX, tilesY ),
            ])

            descr.normals = MeshBuffer([
                SIMD3<Float>(0, 0, -1),
                SIMD3<Float>(0, 0, -1),
                SIMD3<Float>(0, 0, -1),
                SIMD3<Float>(0, 0, -1),
            ])

            descr.primitives = .triangles([0, 1, 2, 1, 3, 2])

            return (try? MeshResource.generate(from: [descr]))
                ?? .generatePlane(width: width, height: height)
        }
    }
}
