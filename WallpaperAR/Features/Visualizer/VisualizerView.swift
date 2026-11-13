// VisualizerView.swift
// Vista principal del visualizador AR.
// ARViewContainer maneja la sesión AR completa.
// VisualizerViewModel recibe callbacks de superficie/error para las
// métricas y expone el catálogo para WallpaperSelectorView.

import SwiftUI

struct VisualizerView: View {

    @StateObject private var viewModel: VisualizerViewModel
    private let materialProvider = RealityKitMaterialProvider()

    /// - Parameters:
    ///   - wallpaper: Tapiz inicialmente seleccionado.
    ///   - catalog: Catálogo completo para el selector. Si está vacío,
    ///     se usa `[wallpaper]` (comportamiento previo, un solo tapiz).
    init(wallpaper: Wallpaper, catalog: [Wallpaper] = []) {
        _viewModel = StateObject(
            wrappedValue: VisualizerViewModel(wallpaper: wallpaper, catalog: catalog)
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Cámara AR a pantalla completa
            ARViewContainer(
                wallpaper: viewModel.selectedWallpaper,
                materialProvider: materialProvider,
                onSurfaceUpdate: { surface in
                    viewModel.updateSurface(surface)
                },
                onSessionError: { message in
                    viewModel.reportSessionError(message)
                }
            )
            .ignoresSafeArea()

            // Overlay de métricas + selector
            VStack(spacing: 12) {
                noLiDARBanner
                    .padding(.horizontal)
                    .padding(.top, 8)

                Spacer()

                metricsPanel
                    .padding(.horizontal)

                WallpaperSelectorView(
                    catalog: viewModel.catalog,
                    selectedWallpaper: viewModel.selectedWallpaper,
                    onSelect: { wallpaper in
                        viewModel.selectWallpaper(wallpaper)
                    }
                )
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
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

    /// Panel inferior: prioriza el error de sesión, luego las métricas de
    /// la pared detectada, y por último el indicador de escaneo.
    @ViewBuilder
    private var metricsPanel: some View {
        if let error = viewModel.sessionError {
            errorBanner(error)
        } else if let surface = viewModel.detectedSurface, let tiling = viewModel.tiling {
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

    /// Banner visible de error de sesión AR. Antes de este banner, un
    /// permiso de cámara denegado o un dispositivo no compatible dejaba
    /// la app aparentemente "sin interfaz": pantalla negra de la cámara
    /// y el indicador de escaneo girando para siempre, sin ninguna pista
    /// de qué estaba fallando.
    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
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
                textureFile: "tapiz_referencia.jpg",
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
