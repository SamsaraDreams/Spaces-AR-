// ARWallDetector.swift
// Implementación de WallDetecting usando ARKit.
// Detecta planos verticales (paredes) y los convierte a WallSurface del dominio.
// iPhone 12 no-Pro: sin LiDAR → detección por feature points visuales.
//
// ESTADO ACTUAL: esta clase NO está instanciada por ningún código activo.
// ARViewContainer.Coordinator (Features/Visualizer/ARViewContainer.swift)
// unificó la propiedad de la ARSession directamente en el propio
// Coordinator (así ARView y sesión son el mismo objeto; ver el comentario
// de cabecera de ese archivo) y duplica aquí la misma lógica de detección.
// Se conserva este archivo —y el protocolo WallDetecting— como semilla
// para una futura inyección de dependencias/mocking en tests de UI,
// pero no se elimina unilateralmente en este pase para no tomar una
// decisión de arquitectura fuera del alcance solicitado. Sus `print`
// se mantienen envueltos en `#if DEBUG` para no filtrar logs en Release,
// igual que el resto del proyecto.

import ARKit
import Foundation

/// Implementación de `WallDetecting` basada en `ARSession` de ARKit.
/// Inicia una sesión AR configurada para detectar planos verticales y
/// notifica al caller vía `onSurfaceUpdate` cada vez que se detecta
/// o actualiza una pared.
final class ARWallDetector: NSObject, WallDetecting {

    // MARK: - WallDetecting

    var onSurfaceUpdate: ((WallSurface) -> Void)?

    func start() {
        guard ARWorldTrackingConfiguration.isSupported else {
            #if DEBUG
            print("[ARWallDetector] ARWorldTracking no soportado en este dispositivo.")
            #endif
            return
        }
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .vertical          // solo paredes
        config.environmentTexturing = .none        // ahorra GPU en MVP
        session.delegate = self
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() {
        session.pause()
    }

    // MARK: - Private

    private let session = ARSession()

    /// Convierte un `ARPlaneAnchor` vertical en un `WallSurface` del dominio.
    private func wallSurface(from anchor: ARPlaneAnchor) -> WallSurface? {
        guard anchor.alignment == .vertical else { return nil }
        // extent.x = ancho del plano detectado (metros)
        // extent.z = alto del plano detectado (metros)
        // ARKit usa Z como eje "hacia arriba" en planos verticales.
        let width  = Double(anchor.planeExtent.width)
        let height = Double(anchor.planeExtent.height)
        guard width > 0.1, height > 0.1 else { return nil } // descartar ruido
        return WallSurface(
            orientation: .vertical,
            widthM: width,
            heightM: height
        )
    }
}

// MARK: - ARSessionDelegate

extension ARWallDetector: ARSessionDelegate {

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        notify(anchors)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        notify(anchors)
    }

    private func notify(_ anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let plane = anchor as? ARPlaneAnchor,
                  let surface = wallSurface(from: plane) else { continue }
            DispatchQueue.main.async { [weak self] in
                self?.onSurfaceUpdate?(surface)
            }
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        #if DEBUG
        print("[ARWallDetector] Error de sesión: \(error.localizedDescription)")
        #endif
    }

    func sessionWasInterrupted(_ session: ARSession) {
        #if DEBUG
        print("[ARWallDetector] Sesión interrumpida.")
        #endif
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        start() // reiniciar automáticamente
    }
}
