// ContentView.swift
// Pantalla de inicio: carga el catálogo (CatalogLoader) y muestra el
// primer papel tapiz disponible, con un botón para entrar al visualizador
// AR llevando el catálogo completo para el selector dentro de la cámara.

import SwiftUI

struct ContentView: View {

    /// Catálogo cargado desde catalog.json. Nunca vacío: si la carga falla
    /// (recurso ausente, JSON corrupto) se usa `fallbackWallpaper` como
    /// único elemento, para que la app siga siendo utilizable.
    private let catalog: [Wallpaper]
    private let selectedWallpaper: Wallpaper

    /// Tapiz de reserva usado únicamente si CatalogLoader no puede leer
    /// catalog.json. Debe coincidir con la entrada real del catálogo
    /// (ver WallpaperAR/Resources/catalog.json) para que, si el bundle
    /// *sí* tiene el recurso pero algo falla, el usuario siga viendo un
    /// tapiz coherente con el que hay documentado en el proyecto.
    private static let fallbackWallpaper = Wallpaper(
        name: "Tapiz Referencia (53 cm)",
        // NOTA DE BUG CORREGIDO: `textureFile` debe incluir la extensión
        // del archivo (ver el doc-comment de Wallpaper.swift: "e.g.
        // tapiz_floral.jpg", y catalog.json: "tapiz_referencia.jpg").
        // Esta constante usaba "tapiz_referencia" sin extensión, por lo
        // que UIImage(named:) no encontraba el recurso suelto del bundle
        // (no está en un Asset Catalog). Resultado: el material de
        // RealityKit se construía con textura nula y el tapiz nunca se
        // veía proyectado sobre la pared detectada.
        textureFile: "tapiz_referencia.jpg",
        patternSpec: PatternSpec(
            patternWidthM: 0.53,
            patternHeightM: 0.53,
            textureWidthPx: 560,
            textureHeightPx: 560
        ),
        tileable: true
    )

    init() {
        if let loaded = try? CatalogLoader.loadWallpapers(), !loaded.isEmpty {
            catalog = loaded
        } else {
            catalog = [Self.fallbackWallpaper]
        }
        selectedWallpaper = catalog[0]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icono y título
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 72))
                        .foregroundStyle(.tint)
                    Text("Space interiorismo AR")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
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
                    VisualizerView(wallpaper: selectedWallpaper, catalog: catalog)
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
            // Miniatura de la textura real del tapiz
            Group {
                if let uiImg = UIImage(named: selectedWallpaper.textureFile) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.systemGray5)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedWallpaper.name)
                    .font(.subheadline.bold())
                Text("Patrón: \(selectedWallpaper.patternSpec.patternWidthM * 100, specifier: "%.0f") × \(selectedWallpaper.patternSpec.patternHeightM * 100, specifier: "%.0f") cm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Rollo: 10 m × 53 cm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if catalog.count > 1 {
                    Text("+ \(catalog.count - 1) tapiz\(catalog.count - 1 == 1 ? "" : "es") más en el catálogo")
                        .font(.caption2)
                        .foregroundStyle(.tint)
                }
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
