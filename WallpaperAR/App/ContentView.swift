// ContentView.swift
// Pantalla de inicio: muestra el papel tapiz de referencia
// y un botón para entrar al visualizador AR.

import SwiftUI

struct ContentView: View {

    private let referenceWallpaper = Wallpaper(
        id: WallpaperID(),
        name: "Tapiz Referencia (53 cm)",
        textureFile: "tapiz_referencia",
        patternSpec: PatternSpec(
            patternWidthM: 0.53,
            patternHeightM: 0.53,
            textureWidthPx: 560,
            textureHeightPx: 560
        ),
        tileable: true
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icono y título
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 72))
                        .foregroundStyle(.tint)
                    Text("WallpaperAR")
                        .font(.largeTitle.bold())
                    Text("Visualiza papel tapiz en tu pared real")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Tarjeta del tapiz seleccionado
                wallpaperCard

                Spacer()

                // Botón principal
                NavigationLink {
                    VisualizerView(wallpaper: referenceWallpaper)
                } label: {
                    Label("Ver en mi pared", systemImage: "arkit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .padding(.horizontal)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }

    private var wallpaperCard: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(referenceWallpaper.name)
                    .font(.subheadline.bold())
                Text("Patrón: \(referenceWallpaper.patternSpec.patternWidthM * 100, specifier: "%.0f") × \(referenceWallpaper.patternSpec.patternHeightM * 100, specifier: "%.0f") cm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Rollo: 10 m × 53 cm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}

#Preview {
    ContentView()
}
