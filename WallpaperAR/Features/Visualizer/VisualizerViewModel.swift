// VisualizerViewModel.swift
// Estado observable del visualizador AR.
// La sesión AR la maneja ARViewContainer directamente.
// Este ViewModel recibe callbacks de superficie y de error de sesión,
// calcula métricas, y expone el catálogo para el selector de tapices.

import Foundation

@MainActor
final class VisualizerViewModel: ObservableObject {

    // MARK: - Estado público

    /// Superficie detectada más reciente (nil = buscando pared)
    @Published private(set) var detectedSurface: WallSurface?

    /// Tiling UV calculado para la superficie actual
    @Published private(set) var tiling: UVScaleCalculator.TilingResult?

    /// Número de rollos necesarios
    @Published private(set) var rollsNeeded: Int = 0

    /// Papel tapiz actualmente seleccionado
    @Published private(set) var selectedWallpaper: Wallpaper

    /// Mensaje de error de sesión AR (nil = sin errores). Antes de este
    /// campo, un fallo de ARSession (p. ej. permiso de cámara denegado)
    /// era invisible para el usuario: la pantalla se quedaba mostrando
    /// indefinidamente "Apunta a una pared…" sin explicar por qué nunca
    /// detectaba nada — percibido como "la app no tiene interfaz / no
    /// responde". Ver VisualizerView.errorBanner.
    @Published private(set) var sessionError: String?

    /// Catálogo de tapices disponibles para el selector horizontal.
    /// Garantizado no-vacío: siempre incluye al menos `selectedWallpaper`.
    let catalog: [Wallpaper]

    // MARK: - Init

    init(wallpaper: Wallpaper, catalog: [Wallpaper] = []) {
        self.selectedWallpaper = wallpaper
        self.catalog = catalog.isEmpty ? [wallpaper] : catalog
    }

    // MARK: - Interfaz pública

    /// Llamado por ARViewContainer cuando detecta o actualiza una pared.
    func updateSurface(_ surface: WallSurface) {
        // Una superficie detectada con éxito implica que la sesión AR
        // sí está funcionando: limpiamos cualquier error previo.
        sessionError = nil
        detectedSurface = surface
        recomputeMetrics(for: surface)
    }

    /// Llamado desde la barra de selección (WallpaperSelectorView) cuando
    /// el usuario elige un tapiz distinto. Recalcula el tiling sobre la
    /// pared ya detectada, si existe, sin perder el escaneo en curso.
    func selectWallpaper(_ wallpaper: Wallpaper) {
        guard wallpaper != selectedWallpaper else { return }
        selectedWallpaper = wallpaper
        if let surface = detectedSurface {
            recomputeMetrics(for: surface)
        }
    }

    /// Llamado por ARViewContainer cuando la sesión AR falla
    /// (dispositivo no compatible, permiso de cámara denegado, etc.).
    func reportSessionError(_ message: String) {
        sessionError = message
    }

    // MARK: - Privado

    private func recomputeMetrics(for surface: WallSurface) {
        tiling = UVScaleCalculator.tiling(
            wallWidthM: surface.widthM,
            wallHeightM: surface.heightM,
            patternSpec: selectedWallpaper.patternSpec
        )
        rollsNeeded = UVScaleCalculator.rollsNeeded(for: surface)
    }
}
