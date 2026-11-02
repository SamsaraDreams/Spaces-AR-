// WallDetecting.swift
// Contrato del servicio de detección de paredes.
// Sin import de ARKit todavía: define la frontera que la capa AR implementará
// en Fase 3. Mantener este protocolo en Swift puro permite inyectar un mock
// en pruebas y mantener las vistas desacopladas de ARKit.

import Foundation

/// Servicio que detecta superficies verticales (paredes) y las reporta
/// como `WallSurface` del dominio.
protocol WallDetecting: AnyObject {

    /// Comienza la sesión de detección de planos verticales.
    func start()

    /// Detiene la sesión y libera recursos.
    func stop()

    /// Callback invocado cuando se detecta o actualiza una superficie.
    var onSurfaceUpdate: ((WallSurface) -> Void)? { get set }
}
