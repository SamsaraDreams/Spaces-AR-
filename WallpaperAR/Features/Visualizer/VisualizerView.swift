// VisualizerView.swift
// Vista principal del visualizador AR.
// Muestra el ARView a pantalla completa con un overlay de métricas
// (dimensiones de pared, repeticiones UV, rollos necesarios).
// Aviso de "sin oclusión automática" visible mientras no hay LiDAR.

import SwiftUI

struct VisualizerView: View {

    @StateObject private var viewModel: VisualizerViewModel
    private let materialProvider = RealityKitMaterialProvider()

    init(wallpaper: Wallpaper) {
        let detector = ARWallDetector()
        _viewModel = StateObject(
            wrappedValue: VisualizerViewModel(
                wallpaper: wallpaper,
                wallDetector: detector
            )
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Cámara AR a pantalla completa
            ARViewContainer(
                wallpaper: viewModel.selectedWallpaper,
                materialProvider: materialProvider
            )
            .ignoresSafeArea()

            // Overlay de métricas
            VStack(spacing: 0) {
                noLiDARBanner
                    .padding(.horizontal)
                    .padding(.top, 8)

                Spacer()

                metricsPanel
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            }
        }
        .onAppear  { viewModel.startAR() }
        .onDisappear { viewModel.stopAR() }
        .navigationTitle("Visualizador AR")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subvistas

    /// Aviso fijo: iPhone 12 no tiene LiDAR → sin oclusión automática
    private var noLiDARBanner: some View {
        Label("Sin oclusión automática (no hay LiDAR)", systemImage: "exclamationmark.triangle")
            .font(.caption2.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }

    /// Panel inferior con métricas de la pared detectada
    @ViewBuilder
    private var metricsPanel: some View {
        if let surface = viewModel.detectedSurface, let tiling = viewModel.tiling {
            VStack(alignment: .leading, spacing: 8) {
                Label("Pared detectada", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)

                Divider()

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                    metricRow("Dimensiones",
                              "\(surface.widthM.fmt1) × \(surface.heightM.fmt1) m")
                    metricRow("Repeticiones X",
                              "\(tiling.tilesX.fmt2) rep.")
                    metricRow("Repeticiones Y",
                              "\(tiling.tilesY.fmt2) rep.")
                    metricRow("Rollos necesarios",
                              "\(viewModel.rollsNeeded) rollo\(viewModel.rollsNeeded == 1 ? "" : "s")")
                }
                .font(.caption)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        } else {
            scanningIndicator
        }
    }

    private var scanningIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(.white)
            Text("Apunta a una pared para detectarla…")
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func metricRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(.primary)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Helpers de formato

private extension Double {
    var fmt1: String { String(format: "%.1f", self) }
    var fmt2: String { String(format: "%.2f", self) }
}

#Preview {
    NavigationStack {
        VisualizerView(
            wallpaper: Wallpaper(
                id: WallpaperID(),
                name: "Tapiz Referencia",
                textureFile: "tapiz_referencia",
                patternSpec: PatternSpec(
                    patternWidthM: 0.53,
                    patternHeightM: 0.53,
                    textureWidthPx: 560,
                    textureHeightPx: 560
                ),
                tileable: true
            )
        )
    }
}
