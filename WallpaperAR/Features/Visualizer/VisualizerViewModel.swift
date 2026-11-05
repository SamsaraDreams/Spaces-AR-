// VisualizerViewModel.swift
// Estado observable del visualizador AR.
// La sesión AR la maneja ARViewContainer directamente.
// Este ViewModel solo recibe callbacks de superficie y calcula métricas.

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
    @Published var selectedWallpaper: Wallpaper

    // MARK: - Init

    init(wallpaper: Wallpaper) {
        self.selectedWallpaper = wallpaper
    }

    // MARK: - Interfaz pública

    /// Llamado por ARViewContainer cuando detecta o actualiza una pared.
    func updateSurface(_ surface: WallSurface) {
        detectedSurface = surface
        let t = UVScaleCalculator.tiling(
            wallWidthM:  surface.widthM,
            wallHeightM: surface.heightM,
            patternSpec: selectedWallpaper.patternSpec
        )
        tiling = t
        rollsNeeded = UVScaleCalculator.rollsNeeded(for: surface)
    }
}
