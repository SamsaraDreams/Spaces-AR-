// VisualizerViewModel.swift
// Lógica del visualizador AR.
// Conecta el servicio de detección (WallDetecting) con la vista,
// calcula métricas UV y rollos, y expone el estado al UI via @Published.

import Combine
import Foundation

/// Estado observable del visualizador AR.
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

    /// true mientras ARKit está buscando planos
    @Published private(set) var isScanning = false

    // MARK: - Init

    init(wallpaper: Wallpaper, wallDetector: WallDetecting) {
        self.selectedWallpaper = wallpaper
        self.wallDetector = wallDetector
        bindDetector()
    }

    // MARK: - Ciclo de vida

    func startAR() {
        isScanning = true
        wallDetector.start()
    }

    func stopAR() {
        isScanning = false
        wallDetector.stop()
    }

    // MARK: - Private

    private let wallDetector: WallDetecting

    private func bindDetector() {
        wallDetector.onSurfaceUpdate = { [weak self] surface in
            guard let self else { return }
            Task { @MainActor in
                self.detectedSurface = surface
                self.recalculate(surface: surface)
            }
        }
    }

    private func recalculate(surface: WallSurface) {
        let t = UVScaleCalculator.tiling(
            wallWidthM: surface.widthM,
            wallHeightM: surface.heightM,
            patternSpec: selectedWallpaper.patternSpec
        )
        tiling = t
        rollsNeeded = UVScaleCalculator.rollsNeeded(for: surface)
    }
}
